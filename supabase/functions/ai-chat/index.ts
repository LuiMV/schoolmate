import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

interface ChatBody {
  session_id: string;
  message: string;
  resource_id?: string;
  subject?: string;
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
    const body: ChatBody = await req.json();
    const authHeader = req.headers.get("Authorization") || "";

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );

    let messages: { role: string; content: string }[] = [];
    let effectiveResourceId = body.resource_id;
    let effectiveSubject = body.subject;

    if (body.session_id) {
      const { data: session, error: sessionErr } = await supabase
        .from("chat_sessions")
        .select("user_id, resource_id, subject")
        .eq("id", body.session_id)
        .single();

      if (sessionErr || !session) {
        throw new Error("Session not found or access denied");
      }

      effectiveResourceId = body.resource_id || session.resource_id;
      effectiveSubject = body.subject || session.subject;

      const { data: msgHistory, error: msgErr } = await supabase
        .from("chat_messages")
        .select("role, content")
        .eq("session_id", body.session_id)
        .order("created_at", { ascending: true });

      if (msgErr) throw msgErr;
      if (msgHistory) {
        messages = msgHistory.map((m) => ({
          role: m.role as "user" | "assistant" | "system",
          content: m.content,
        }));
      }
    }

    let resourceContext = "";
    if (effectiveResourceId) {
      const { data: analysis } = await supabase
        .from("resource_analysis")
        .select("summary, full_text, tags, flashcards")
        .eq("resource_id", effectiveResourceId)
        .maybeSingle();

      if (analysis) {
        resourceContext = `\n\nYou are tutoring about this document:\nTitle and summary: ${analysis.summary || ""}\nFull content:\n${(analysis.full_text || "").substring(0, 30000)}\nTags: ${(analysis.tags || []).join(", ")}`;
      }
    }

    const systemPrompt =
      `You are a helpful educational tutor for high school students.` +
      (effectiveSubject ? ` Subject: ${effectiveSubject}.` : "") +
      ` Give clear, age-appropriate explanations. Encourage critical thinking.` +
      resourceContext;

    const groqMessages = [
      { role: "system", content: systemPrompt },
      ...messages,
      { role: "user", content: body.message },
    ];

    const groqRes = await fetch(
      "https://api.groq.com/openai/v1/chat/completions",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${Deno.env.get("GROQ_API_KEY_CHAT")}`,
        },
        body: JSON.stringify({
          model: "meta-llama/llama-4-scout-17b-16e-instruct",
          messages: groqMessages,
          max_tokens: 1500,
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
    const responseText = groqData.choices[0].message.content;

    return new Response(JSON.stringify({ response: responseText }), {
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
