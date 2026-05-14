import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

interface IngestionBody {
  resource_id: string;
  file_text: string;
  title: string;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    const body: IngestionBody = await req.json();
    const authHeader = req.headers.get("Authorization") || "";
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );

    const groqRes = await fetch(
      "https://api.groq.com/openai/v1/chat/completions",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${Deno.env.get("GROQ_API_KEY_INGESTION")}`,
        },
        body: JSON.stringify({
          model: "meta-llama/llama-4-scout-17b-16e-instruct",
          messages: [
            {
              role: "system",
              content:
                "You are an AI that analyzes educational resources. Return ONLY valid JSON without markdown formatting or code fences.",
            },
            {
              role: "user",
              content: `Analyze this educational resource titled "${body.title}".\n\nContent:\n${
                body.file_text || "(no text content available)"
              }\n\nGenerate a JSON object with exactly these fields:
{
  "summary": "a brief 2-3 sentence summary of the resource",
  "tags": ["tag1", "tag2", "tag3", "tag4", "tag5"],
  "flashcards": [
    {"question": "question text", "answer": "answer text"}
  ],
  "quiz": {
    "questions": [
      {
        "question": "question text",
        "options": ["option1", "option2", "option3", "option4"],
        "correct_index": 0,
        "explanation": "why this answer is correct"
      }
    ]
  },
  "metadata": {
    "main_topic": "the main subject area",
    "difficulty": "beginner/intermediate/advanced",
    "key_concepts": ["concept1", "concept2"]
  }
}

Generate 5 flashcards and 5 quiz questions. Return ONLY the JSON object, no other text.`,
            },
          ],
          max_tokens: 3000,
          temperature: 0.7,
          top_p: 1,
          stream: false,
        }),
      },
    );

    if (!groqRes.ok) {
      const errText = await groqRes.text();
      throw new Error(`Groq error: ${errText}`);
    }

    const groqData = await groqRes.json();
    const rawContent = groqData.choices[0].message.content;
    const cleaned = rawContent.replace(/```json|```/g, "").trim();
    const analysis = JSON.parse(cleaned);

    const { data, error } = await supabase.from("resource_analysis").upsert(
      {
        resource_id: body.resource_id,
        summary: analysis.summary,
        full_text: body.file_text.substring(0, 50000),
        metadata: analysis.metadata,
        tags: analysis.tags,
        flashcards: analysis.flashcards,
        quiz: analysis.quiz,
      },
      { onConflict: "resource_id" },
    ).select().single();

    if (error) throw error;

    return new Response(JSON.stringify(data), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
