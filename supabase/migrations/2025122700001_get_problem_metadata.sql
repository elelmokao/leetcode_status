-- 1. 確保 api schema 存在
CREATE SCHEMA IF NOT EXISTS api;

-- 2. 建立 RPC 函數
CREATE OR REPLACE FUNCTION api.get_problem_metadata(input_id int)
RETURNS SETOF public.problems
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, api
AS $$
  SELECT * FROM public.problems
  WHERE id = input_id;
$$;

-- 3. 權限設定
GRANT USAGE ON SCHEMA api TO anon, authenticated;
GRANT EXECUTE ON FUNCTION api.get_problem_metadata(int) TO anon, authenticated;

-- 4. 註解
COMMENT ON FUNCTION api.get_problem_metadata(int) IS 'Get LeetCode Metadata through problem ID';