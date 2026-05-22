-- Create diary entries table
CREATE TABLE IF NOT EXISTS public.diary_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT,
  content TEXT,
  entry_date DATE NOT NULL,
  image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE public.diary_entries ENABLE ROW LEVEL SECURITY;

-- Policies: users can only access their own entries
CREATE POLICY "Users can view own entries"
  ON public.diary_entries FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own entries"
  ON public.diary_entries FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own entries"
  ON public.diary_entries FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own entries"
  ON public.diary_entries FOR DELETE USING (auth.uid() = user_id);

-- Create storage bucket for diary images
INSERT INTO storage.buckets (id, name, public)
VALUES ('diary-images', 'diary-images', true)
ON CONFLICT (id) DO NOTHING;

-- Allow authenticated users to access only their own folder in the diary-images bucket
CREATE POLICY "Give users access to own folder"
  ON storage.objects FOR ALL USING (
    auth.role() = 'authenticated'
    AND bucket_id = 'diary-images'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
