PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS schema_versions (
  version INTEGER PRIMARY KEY NOT NULL,
  applied_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS projects (
  id TEXT PRIMARY KEY NOT NULL,
  project_name TEXT NOT NULL,
  project_name_normalized TEXT NOT NULL,
  client_oem TEXT,
  site_location TEXT,
  site_location_normalized TEXT,
  site_contact_name TEXT,
  site_contact_phone TEXT,
  coordinator_name TEXT,
  project_manager_name TEXT,
  status TEXT,
  notes TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  archived_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_projects_name_normalized ON projects(project_name_normalized);
CREATE INDEX IF NOT EXISTS idx_projects_client_oem ON projects(client_oem);
CREATE INDEX IF NOT EXISTS idx_projects_updated_at ON projects(updated_at);

CREATE TABLE IF NOT EXISTS raw_captures (
  id TEXT PRIMARY KEY NOT NULL,
  channel TEXT NOT NULL CHECK (channel IN ('manual_text', 'wechat_text', 'sms_text', 'audio', 'manual_form', 'unknown')),
  raw_text TEXT,
  transcript_text TEXT,
  audio_file_path TEXT,
  attachment_group_id TEXT,
  capture_time TEXT NOT NULL,
  capture_timezone TEXT,
  captured_by_agentee_name TEXT,
  classification_type TEXT NOT NULL DEFAULT 'unknown' CHECK (classification_type IN ('task', 'project', 'meeting', 'mixed', 'unknown')),
  classification_confidence REAL,
  parse_status TEXT NOT NULL DEFAULT 'new' CHECK (parse_status IN ('new', 'parsed', 'reviewed', 'failed')),
  parse_version TEXT,
  source_hash TEXT,
  created_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_raw_captures_channel ON raw_captures(channel);
CREATE INDEX IF NOT EXISTS idx_raw_captures_capture_time ON raw_captures(capture_time);
CREATE INDEX IF NOT EXISTS idx_raw_captures_classification_type ON raw_captures(classification_type);
CREATE INDEX IF NOT EXISTS idx_raw_captures_parse_status ON raw_captures(parse_status);
CREATE INDEX IF NOT EXISTS idx_raw_captures_source_hash ON raw_captures(source_hash);

CREATE TABLE IF NOT EXISTS tasks (
  id TEXT PRIMARY KEY NOT NULL,
  project_id TEXT,
  task_type TEXT NOT NULL CHECK (task_type IN ('site_survey', 'installation', 'tuning', 'handover', 'maintenance', 'unknown')),
  task_title TEXT,
  task_title_normalized TEXT,
  description TEXT,
  scheduled_date TEXT,
  start_time_local TEXT,
  time_bucket TEXT,
  duration_minutes INTEGER,
  location_snapshot TEXT,
  worker_name TEXT,
  worker_phone TEXT,
  coordinator_name TEXT,
  project_manager_name TEXT,
  agentee_name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'planned' CHECK (status IN ('planned', 'in_progress', 'blocked', 'completed', 'cancelled')),
  priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
  source_capture_id TEXT,
  dedup_key TEXT,
  is_provisional INTEGER NOT NULL DEFAULT 0 CHECK (is_provisional IN (0, 1)),
  needs_review INTEGER NOT NULL DEFAULT 0 CHECK (needs_review IN (0, 1)),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  archived_at TEXT,
  FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE SET NULL,
  FOREIGN KEY(source_capture_id) REFERENCES raw_captures(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_tasks_project_id ON tasks(project_id);
CREATE INDEX IF NOT EXISTS idx_tasks_scheduled_date ON tasks(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_tasks_task_type ON tasks(task_type);
CREATE INDEX IF NOT EXISTS idx_tasks_worker_name ON tasks(worker_name);
CREATE INDEX IF NOT EXISTS idx_tasks_dedup_key ON tasks(dedup_key);
CREATE INDEX IF NOT EXISTS idx_tasks_needs_review ON tasks(needs_review);
CREATE UNIQUE INDEX IF NOT EXISTS idx_tasks_finalized_dedup_key ON tasks(dedup_key)
WHERE is_provisional = 0 AND dedup_key IS NOT NULL;

CREATE TABLE IF NOT EXISTS meetings (
  id TEXT PRIMARY KEY NOT NULL,
  title TEXT,
  meeting_datetime TEXT,
  meeting_timezone TEXT,
  location_text TEXT,
  summary TEXT,
  minutes_markdown TEXT,
  transcript_text TEXT,
  source_capture_id TEXT,
  source_hash TEXT,
  review_state TEXT NOT NULL DEFAULT 'draft_recording' CHECK (
    review_state IN (
      'draft_recording',
      'recorded_pending_transcription',
      'transcribing',
      'transcription_failed',
      'transcribed_pending_extraction',
      'extracting',
      'extraction_failed',
      'manual_review_only',
      'review_required',
      'review_in_progress',
      'task_candidate_resolution',
      'finalized',
      'reopened',
      'archived',
      'cancelled'
    )
  ),
  needs_review INTEGER NOT NULL DEFAULT 1 CHECK (needs_review IN (0, 1)),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  archived_at TEXT,
  FOREIGN KEY(source_capture_id) REFERENCES raw_captures(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_meetings_meeting_datetime ON meetings(meeting_datetime);
CREATE INDEX IF NOT EXISTS idx_meetings_source_hash ON meetings(source_hash);
CREATE INDEX IF NOT EXISTS idx_meetings_needs_review ON meetings(needs_review);

CREATE TABLE IF NOT EXISTS meeting_projects (
  meeting_id TEXT NOT NULL,
  project_id TEXT NOT NULL,
  PRIMARY KEY(meeting_id, project_id),
  FOREIGN KEY(meeting_id) REFERENCES meetings(id) ON DELETE CASCADE,
  FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS meeting_tasks (
  meeting_id TEXT NOT NULL,
  task_id TEXT NOT NULL,
  extraction_confidence REAL,
  PRIMARY KEY(meeting_id, task_id),
  FOREIGN KEY(meeting_id) REFERENCES meetings(id) ON DELETE CASCADE,
  FOREIGN KEY(task_id) REFERENCES tasks(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS people (
  id TEXT PRIMARY KEY NOT NULL,
  name TEXT NOT NULL,
  name_normalized TEXT NOT NULL,
  phone TEXT,
  role_hint TEXT CHECK (role_hint IN ('worker', 'site_contact', 'coordinator', 'project_manager', 'other')),
  company TEXT,
  notes TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_people_name_normalized ON people(name_normalized);
CREATE INDEX IF NOT EXISTS idx_people_phone ON people(phone);

CREATE TABLE IF NOT EXISTS project_people (
  project_id TEXT NOT NULL,
  person_id TEXT NOT NULL,
  relation_type TEXT NOT NULL CHECK (relation_type IN ('worker', 'site_contact', 'coordinator', 'project_manager')),
  PRIMARY KEY(project_id, person_id, relation_type),
  FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE,
  FOREIGN KEY(person_id) REFERENCES people(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS attachments (
  id TEXT PRIMARY KEY NOT NULL,
  owner_record_type TEXT NOT NULL CHECK (owner_record_type IN ('raw_capture', 'task', 'meeting', 'project', 'export_bundle')),
  owner_record_id TEXT NOT NULL,
  file_path TEXT NOT NULL,
  mime_type TEXT,
  file_size INTEGER,
  checksum TEXT,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS imports (
  id TEXT PRIMARY KEY NOT NULL,
  bundle_name TEXT NOT NULL,
  bundle_path TEXT NOT NULL,
  bundle_checksum TEXT,
  import_time TEXT NOT NULL,
  preview_summary_json TEXT,
  decision_summary_json TEXT,
  status TEXT NOT NULL CHECK (status IN ('previewed', 'applied', 'failed', 'cancelled'))
);

CREATE TABLE IF NOT EXISTS exports (
  id TEXT PRIMARY KEY NOT NULL,
  bundle_name TEXT NOT NULL,
  bundle_path TEXT NOT NULL,
  bundle_checksum TEXT,
  export_scope_type TEXT NOT NULL,
  export_scope_value TEXT,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS audit_logs (
  id TEXT PRIMARY KEY NOT NULL,
  record_type TEXT NOT NULL,
  record_id TEXT NOT NULL,
  action_type TEXT NOT NULL CHECK (action_type IN ('create', 'update', 'merge', 'dedup_reject', 'import_apply', 'export_create', 'ai_extract', 'finalize', 'reopen', 'archive')),
  before_json TEXT,
  after_json TEXT,
  source_capture_id TEXT,
  actor_name TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY(source_capture_id) REFERENCES raw_captures(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS report_runs (
  id TEXT PRIMARY KEY NOT NULL,
  report_type TEXT NOT NULL,
  filter_json TEXT,
  output_format TEXT NOT NULL CHECK (output_format IN ('in_app', 'pdf', 'csv', 'json')),
  output_path TEXT,
  created_at TEXT NOT NULL
);

CREATE VIRTUAL TABLE IF NOT EXISTS projects_fts USING fts5(
  project_name,
  site_location,
  notes,
  content=''
);

CREATE VIRTUAL TABLE IF NOT EXISTS tasks_fts USING fts5(
  task_title,
  description,
  worker_name,
  location_snapshot,
  content=''
);

CREATE VIRTUAL TABLE IF NOT EXISTS meetings_fts USING fts5(
  title,
  summary,
  minutes_markdown,
  transcript_text,
  content=''
);

CREATE VIRTUAL TABLE IF NOT EXISTS raw_captures_fts USING fts5(
  raw_text,
  transcript_text,
  content=''
);

CREATE VIRTUAL TABLE IF NOT EXISTS people_fts USING fts5(
  name,
  phone,
  company,
  notes,
  content=''
);

CREATE TRIGGER IF NOT EXISTS projects_ai AFTER INSERT ON projects BEGIN
  INSERT INTO projects_fts(rowid, project_name, site_location, notes)
  VALUES (new.rowid, new.project_name, new.site_location, new.notes);
END;

CREATE TRIGGER IF NOT EXISTS projects_au AFTER UPDATE ON projects BEGIN
  INSERT INTO projects_fts(projects_fts, rowid, project_name, site_location, notes)
  VALUES ('delete', old.rowid, old.project_name, old.site_location, old.notes);
  INSERT INTO projects_fts(rowid, project_name, site_location, notes)
  VALUES (new.rowid, new.project_name, new.site_location, new.notes);
END;

CREATE TRIGGER IF NOT EXISTS projects_ad AFTER DELETE ON projects BEGIN
  INSERT INTO projects_fts(projects_fts, rowid, project_name, site_location, notes)
  VALUES ('delete', old.rowid, old.project_name, old.site_location, old.notes);
END;

CREATE TRIGGER IF NOT EXISTS tasks_ai AFTER INSERT ON tasks BEGIN
  INSERT INTO tasks_fts(rowid, task_title, description, worker_name, location_snapshot)
  VALUES (new.rowid, new.task_title, new.description, new.worker_name, new.location_snapshot);
END;

CREATE TRIGGER IF NOT EXISTS tasks_au AFTER UPDATE ON tasks BEGIN
  INSERT INTO tasks_fts(tasks_fts, rowid, task_title, description, worker_name, location_snapshot)
  VALUES ('delete', old.rowid, old.task_title, old.description, old.worker_name, old.location_snapshot);
  INSERT INTO tasks_fts(rowid, task_title, description, worker_name, location_snapshot)
  VALUES (new.rowid, new.task_title, new.description, new.worker_name, new.location_snapshot);
END;

CREATE TRIGGER IF NOT EXISTS tasks_ad AFTER DELETE ON tasks BEGIN
  INSERT INTO tasks_fts(tasks_fts, rowid, task_title, description, worker_name, location_snapshot)
  VALUES ('delete', old.rowid, old.task_title, old.description, old.worker_name, old.location_snapshot);
END;

CREATE TRIGGER IF NOT EXISTS meetings_ai AFTER INSERT ON meetings BEGIN
  INSERT INTO meetings_fts(rowid, title, summary, minutes_markdown, transcript_text)
  VALUES (new.rowid, new.title, new.summary, new.minutes_markdown, new.transcript_text);
END;

CREATE TRIGGER IF NOT EXISTS meetings_au AFTER UPDATE ON meetings BEGIN
  INSERT INTO meetings_fts(meetings_fts, rowid, title, summary, minutes_markdown, transcript_text)
  VALUES ('delete', old.rowid, old.title, old.summary, old.minutes_markdown, old.transcript_text);
  INSERT INTO meetings_fts(rowid, title, summary, minutes_markdown, transcript_text)
  VALUES (new.rowid, new.title, new.summary, new.minutes_markdown, new.transcript_text);
END;

CREATE TRIGGER IF NOT EXISTS meetings_ad AFTER DELETE ON meetings BEGIN
  INSERT INTO meetings_fts(meetings_fts, rowid, title, summary, minutes_markdown, transcript_text)
  VALUES ('delete', old.rowid, old.title, old.summary, old.minutes_markdown, old.transcript_text);
END;

CREATE TRIGGER IF NOT EXISTS raw_captures_ai AFTER INSERT ON raw_captures BEGIN
  INSERT INTO raw_captures_fts(rowid, raw_text, transcript_text)
  VALUES (new.rowid, new.raw_text, new.transcript_text);
END;

CREATE TRIGGER IF NOT EXISTS raw_captures_au AFTER UPDATE ON raw_captures BEGIN
  INSERT INTO raw_captures_fts(raw_captures_fts, rowid, raw_text, transcript_text)
  VALUES ('delete', old.rowid, old.raw_text, old.transcript_text);
  INSERT INTO raw_captures_fts(rowid, raw_text, transcript_text)
  VALUES (new.rowid, new.raw_text, new.transcript_text);
END;

CREATE TRIGGER IF NOT EXISTS raw_captures_ad AFTER DELETE ON raw_captures BEGIN
  INSERT INTO raw_captures_fts(raw_captures_fts, rowid, raw_text, transcript_text)
  VALUES ('delete', old.rowid, old.raw_text, old.transcript_text);
END;

CREATE TRIGGER IF NOT EXISTS people_ai AFTER INSERT ON people BEGIN
  INSERT INTO people_fts(rowid, name, phone, company, notes)
  VALUES (new.rowid, new.name, new.phone, new.company, new.notes);
END;

CREATE TRIGGER IF NOT EXISTS people_au AFTER UPDATE ON people BEGIN
  INSERT INTO people_fts(people_fts, rowid, name, phone, company, notes)
  VALUES ('delete', old.rowid, old.name, old.phone, old.company, old.notes);
  INSERT INTO people_fts(rowid, name, phone, company, notes)
  VALUES (new.rowid, new.name, new.phone, new.company, new.notes);
END;

CREATE TRIGGER IF NOT EXISTS people_ad AFTER DELETE ON people BEGIN
  INSERT INTO people_fts(people_fts, rowid, name, phone, company, notes)
  VALUES ('delete', old.rowid, old.name, old.phone, old.company, old.notes);
END;