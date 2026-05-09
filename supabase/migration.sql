-- ============================================================
-- SCHOOLMATE DATABASE MIGRATION
-- Run this in Supabase SQL Editor
-- ============================================================

-- 1. COURSES
create table courses (
  id uuid default gen_random_uuid() primary key,
  teacher_id uuid not null references profiles(id) on delete cascade,
  name text not null,
  description text,
  subject text not null,
  grade text not null,
  section text not null,
  created_at timestamptz default now()
);

alter table courses enable row level security;

create policy "Teachers can manage their courses"
  on courses for all
  using (teacher_id = auth.uid());

create policy "Students can view courses by grade/section"
  on courses for select
  using (
    exists (
      select 1 from profiles
      where profiles.id = auth.uid()
        and profiles.role = 'Student'
        and courses.grade = profiles.grade
        and courses.section = profiles.section
    )
  );

-- 2. RESOURCES
create table resources (
  id uuid default gen_random_uuid() primary key,
  course_id uuid not null references courses(id) on delete cascade,
  teacher_id uuid not null references profiles(id) on delete cascade,
  title text not null,
  type text not null check (type in ('document', 'video', 'image', 'url')),
  url text,
  file_path text,
  file_name text,
  created_at timestamptz default now()
);

alter table resources enable row level security;

create policy "Teachers can manage their resources"
  on resources for all
  using (teacher_id = auth.uid());

create policy "Students can view course resources"
  on resources for select
  using (
    exists (
      select 1 from courses
      join profiles on profiles.id = auth.uid()
      where courses.id = resources.course_id
        and courses.grade = profiles.grade
        and courses.section = profiles.section
    )
  );

-- 3. COMPREHENSION SCORES
create table comprehension_scores (
  id uuid default gen_random_uuid() primary key,
  course_id uuid not null references courses(id) on delete cascade,
  student_id uuid not null references profiles(id) on delete cascade,
  score int not null check (score >= 0 and score <= 100),
  notes text,
  created_at timestamptz default now(),
  unique (course_id, student_id)
);

alter table comprehension_scores enable row level security;

create policy "Teachers can manage scores"
  on comprehension_scores for all
  using (
    exists (
      select 1 from courses
      where courses.id = comprehension_scores.course_id
        and courses.teacher_id = auth.uid()
    )
  );

create policy "Students can view their own scores"
  on comprehension_scores for select
  using (student_id = auth.uid());

-- 4. AI FEEDBACK (teacher side)
create table ai_feedback (
  id uuid default gen_random_uuid() primary key,
  course_id uuid not null references courses(id) on delete cascade,
  resource_id uuid references resources(id) on delete set null,
  teacher_id uuid not null references profiles(id) on delete cascade,
  feedback_type text not null check (feedback_type in ('resource_analysis', 'common_difficulties')),
  request_text text,
  response_text text,
  created_at timestamptz default now()
);

alter table ai_feedback enable row level security;

create policy "Teachers can manage feedback"
  on ai_feedback for all
  using (teacher_id = auth.uid());

-- 5. QUIZ RESULTS (student side)
create table quiz_results (
  id uuid default gen_random_uuid() primary key,
  course_id uuid not null references courses(id) on delete cascade,
  student_id uuid not null references profiles(id) on delete cascade,
  subject text not null,
  topic text,
  questions jsonb not null,
  answers jsonb not null,
  score int not null check (score >= 0 and score <= 100),
  total_questions int not null,
  correct_answers int not null,
  completed_at timestamptz default now()
);

alter table quiz_results enable row level security;

create policy "Students can manage their quiz results"
  on quiz_results for all
  using (student_id = auth.uid());

create policy "Teachers can view quiz results"
  on quiz_results for select
  using (
    exists (
      select 1 from courses
      where courses.id = quiz_results.course_id
        and courses.teacher_id = auth.uid()
    )
  );

-- 6. STORAGE
insert into storage.buckets (id, name, public) values ('course-resources', 'course-resources', true)
on conflict (id) do nothing;

create policy "Teachers can upload resources"
  on storage.objects for insert
  with check (
    bucket_id = 'course-resources'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Anyone can view resources"
  on storage.objects for select
  using (bucket_id = 'course-resources');
