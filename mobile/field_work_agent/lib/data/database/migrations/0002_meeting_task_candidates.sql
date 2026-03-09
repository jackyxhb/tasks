CREATE TABLE IF NOT EXISTS meeting_task_candidates (
  meeting_id TEXT NOT NULL,
  candidate_id TEXT NOT NULL,
  task_type TEXT NOT NULL CHECK (task_type IN ('site_survey', 'installation', 'tuning', 'handover', 'maintenance', 'unknown')),
  task_title TEXT,
  description TEXT,
  project_name TEXT,
  worker_name TEXT,
  worker_phone TEXT,
  coordinator_name TEXT,
  project_manager_name TEXT,
  scheduled_date_text TEXT,
  start_time_text TEXT,
  duration_text TEXT,
  location_text TEXT,
  state TEXT NOT NULL CHECK (state IN ('new_candidate', 'accepted_as_new_task', 'merged_into_existing_task', 'saved_as_provisional_task', 'rejected')),
  confidence REAL NOT NULL,
  source_snippet TEXT NOT NULL,
  ambiguities_json TEXT NOT NULL,
  linked_task_id TEXT,
  PRIMARY KEY(meeting_id, candidate_id),
  FOREIGN KEY(meeting_id) REFERENCES meetings(id) ON DELETE CASCADE,
  FOREIGN KEY(linked_task_id) REFERENCES tasks(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_meeting_task_candidates_meeting_id ON meeting_task_candidates(meeting_id);
CREATE INDEX IF NOT EXISTS idx_meeting_task_candidates_state ON meeting_task_candidates(state);
CREATE INDEX IF NOT EXISTS idx_meeting_task_candidates_linked_task_id ON meeting_task_candidates(linked_task_id);