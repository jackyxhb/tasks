DROP TABLE IF EXISTS projects_fts;
DROP TABLE IF EXISTS tasks_fts;
DROP TABLE IF EXISTS meetings_fts;
DROP TABLE IF EXISTS raw_captures_fts;
DROP TABLE IF EXISTS people_fts;

CREATE VIRTUAL TABLE IF NOT EXISTS projects_fts USING fts5(
  record_id UNINDEXED,
  project_name,
  site_location,
  notes
);

CREATE VIRTUAL TABLE IF NOT EXISTS tasks_fts USING fts5(
  record_id UNINDEXED,
  task_title,
  description,
  worker_name,
  location_snapshot
);

CREATE VIRTUAL TABLE IF NOT EXISTS meetings_fts USING fts5(
  record_id UNINDEXED,
  title,
  summary,
  minutes_markdown,
  transcript_text
);

CREATE VIRTUAL TABLE IF NOT EXISTS raw_captures_fts USING fts5(
  record_id UNINDEXED,
  raw_text,
  transcript_text
);

CREATE VIRTUAL TABLE IF NOT EXISTS people_fts USING fts5(
  record_id UNINDEXED,
  name,
  phone,
  company,
  notes
);

INSERT INTO projects_fts(record_id, project_name, site_location, notes)
SELECT id, COALESCE(project_name, ''), COALESCE(site_location, ''), COALESCE(notes, '') FROM projects;

INSERT INTO tasks_fts(record_id, task_title, description, worker_name, location_snapshot)
SELECT id, COALESCE(task_title, ''), COALESCE(description, ''), COALESCE(worker_name, ''), COALESCE(location_snapshot, '') FROM tasks;

INSERT INTO meetings_fts(record_id, title, summary, minutes_markdown, transcript_text)
SELECT id, COALESCE(title, ''), COALESCE(summary, ''), COALESCE(minutes_markdown, ''), COALESCE(transcript_text, '') FROM meetings;

INSERT INTO raw_captures_fts(record_id, raw_text, transcript_text)
SELECT id, COALESCE(raw_text, ''), COALESCE(transcript_text, '') FROM raw_captures;

INSERT INTO people_fts(record_id, name, phone, company, notes)
SELECT id, COALESCE(name, ''), COALESCE(phone, ''), COALESCE(company, ''), COALESCE(notes, '') FROM people;

CREATE TRIGGER IF NOT EXISTS projects_ai AFTER INSERT ON projects BEGIN
  INSERT INTO projects_fts(record_id, project_name, site_location, notes)
  VALUES (new.id, COALESCE(new.project_name, ''), COALESCE(new.site_location, ''), COALESCE(new.notes, ''));
END;

CREATE TRIGGER IF NOT EXISTS projects_au AFTER UPDATE ON projects BEGIN
  DELETE FROM projects_fts WHERE record_id = old.id;
  INSERT INTO projects_fts(record_id, project_name, site_location, notes)
  VALUES (new.id, COALESCE(new.project_name, ''), COALESCE(new.site_location, ''), COALESCE(new.notes, ''));
END;

CREATE TRIGGER IF NOT EXISTS projects_ad AFTER DELETE ON projects BEGIN
  DELETE FROM projects_fts WHERE record_id = old.id;
END;

CREATE TRIGGER IF NOT EXISTS tasks_ai AFTER INSERT ON tasks BEGIN
  INSERT INTO tasks_fts(record_id, task_title, description, worker_name, location_snapshot)
  VALUES (new.id, COALESCE(new.task_title, ''), COALESCE(new.description, ''), COALESCE(new.worker_name, ''), COALESCE(new.location_snapshot, ''));
END;

CREATE TRIGGER IF NOT EXISTS tasks_au AFTER UPDATE ON tasks BEGIN
  DELETE FROM tasks_fts WHERE record_id = old.id;
  INSERT INTO tasks_fts(record_id, task_title, description, worker_name, location_snapshot)
  VALUES (new.id, COALESCE(new.task_title, ''), COALESCE(new.description, ''), COALESCE(new.worker_name, ''), COALESCE(new.location_snapshot, ''));
END;

CREATE TRIGGER IF NOT EXISTS tasks_ad AFTER DELETE ON tasks BEGIN
  DELETE FROM tasks_fts WHERE record_id = old.id;
END;

CREATE TRIGGER IF NOT EXISTS meetings_ai AFTER INSERT ON meetings BEGIN
  INSERT INTO meetings_fts(record_id, title, summary, minutes_markdown, transcript_text)
  VALUES (new.id, COALESCE(new.title, ''), COALESCE(new.summary, ''), COALESCE(new.minutes_markdown, ''), COALESCE(new.transcript_text, ''));
END;

CREATE TRIGGER IF NOT EXISTS meetings_au AFTER UPDATE ON meetings BEGIN
  DELETE FROM meetings_fts WHERE record_id = old.id;
  INSERT INTO meetings_fts(record_id, title, summary, minutes_markdown, transcript_text)
  VALUES (new.id, COALESCE(new.title, ''), COALESCE(new.summary, ''), COALESCE(new.minutes_markdown, ''), COALESCE(new.transcript_text, ''));
END;

CREATE TRIGGER IF NOT EXISTS meetings_ad AFTER DELETE ON meetings BEGIN
  DELETE FROM meetings_fts WHERE record_id = old.id;
END;

CREATE TRIGGER IF NOT EXISTS raw_captures_ai AFTER INSERT ON raw_captures BEGIN
  INSERT INTO raw_captures_fts(record_id, raw_text, transcript_text)
  VALUES (new.id, COALESCE(new.raw_text, ''), COALESCE(new.transcript_text, ''));
END;

CREATE TRIGGER IF NOT EXISTS raw_captures_au AFTER UPDATE ON raw_captures BEGIN
  DELETE FROM raw_captures_fts WHERE record_id = old.id;
  INSERT INTO raw_captures_fts(record_id, raw_text, transcript_text)
  VALUES (new.id, COALESCE(new.raw_text, ''), COALESCE(new.transcript_text, ''));
END;

CREATE TRIGGER IF NOT EXISTS raw_captures_ad AFTER DELETE ON raw_captures BEGIN
  DELETE FROM raw_captures_fts WHERE record_id = old.id;
END;

CREATE TRIGGER IF NOT EXISTS people_ai AFTER INSERT ON people BEGIN
  INSERT INTO people_fts(record_id, name, phone, company, notes)
  VALUES (new.id, COALESCE(new.name, ''), COALESCE(new.phone, ''), COALESCE(new.company, ''), COALESCE(new.notes, ''));
END;

CREATE TRIGGER IF NOT EXISTS people_au AFTER UPDATE ON people BEGIN
  DELETE FROM people_fts WHERE record_id = old.id;
  INSERT INTO people_fts(record_id, name, phone, company, notes)
  VALUES (new.id, COALESCE(new.name, ''), COALESCE(new.phone, ''), COALESCE(new.company, ''), COALESCE(new.notes, ''));
END;

CREATE TRIGGER IF NOT EXISTS people_ad AFTER DELETE ON people BEGIN
  DELETE FROM people_fts WHERE record_id = old.id;
END;