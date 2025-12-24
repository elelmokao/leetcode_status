import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.7"

// Define the data structure for LeetCode API
interface LeetCodeProblem {
  stat: {
    frontend_question_id: number;
    question__title: string;
    question__title_slug: string;
    total_acs: number;
    total_submitted: number;
  };
  difficulty: {
    level: number;
  };
  paid_only: boolean;
}

Deno.serve(async (req) => {
  try {
    // 1. Initialize Supabase Client (use Service Role Key to bypass RLS and allow writes)
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // 2. Fetch data from LeetCode
    console.log("Fetching data from LeetCode...")
    const response = await fetch('https://leetcode.com/api/problems/all/')
    const data = await response.json()
    const problemsList: LeetCodeProblem[] = data.stat_status_pairs

    // 3. Format data
    // Only select required fields, and do not provide timestamps; let the database trigger handle them
    const problemsData = problemsList.map(p => ({
      id: p.stat.frontend_question_id,
      slug: p.stat.question__title_slug,
      title: p.stat.question__title,
      difficulty: p.difficulty.level,
      is_paid: p.paid_only
    }))

    const statsData = problemsList.map(p => ({
      problem_id: p.stat.frontend_question_id,
      total_accepted: p.stat.total_acs,
      total_submitted: p.stat.total_submitted
      // collected_at 由資料庫 DEFAULT NOW() 處理
    }))

    console.log(`Processing ${problemsData.length} problems...`)

    // 4. Batch write to database (Upsert)
    // Write in batches (e.g., 500 records per batch) to ensure stability
    const batchSize = 500
    for (let i = 0; i < problemsData.length; i += batchSize) {
      const problemBatch = problemsData.slice(i, i + batchSize)
      const statsBatch = statsData.slice(i, i + batchSize)

      // Upsert to problems table
      const { error: pError } = await supabase
        .from('problems')
        .upsert(problemBatch, { onConflict: 'id' })
      
      if (pError) throw pError

      // Insert into acceptance_stats table
      const { error: sError } = await supabase
        .from('acceptance_stats')
        .insert(statsBatch)

      if (sError) throw sError
      
      console.log(`Synced batch ${i / batchSize + 1}`)
    }

    return new Response(JSON.stringify({ message: "Sync Completed Successfully" }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    })

  } catch (error) {
    console.error("Error:", error.message)
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { "Content-Type": "application/json" },
      status: 500,
    })
  }
})