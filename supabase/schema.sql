-- ============================================================
-- 星図 Supabase スキーマ
-- 作成: 2026-07-05 / 設計: Fable 5 の append-only モデルに基づく
-- 実行: SBI Supabase 管理画面 SQL エディタで一度だけ実行
-- ============================================================

-- イベント台帳（追記専用・削除しない）
create table if not exists star_chart_events (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid references auth.users(id) not null,
  ts           timestamptz not null,             -- イベント発生時刻
  type         text not null,                    -- light / retract / decision
  routine_id   text not null,                    -- R001, R002 等
  credit       numeric,                          -- light の場合の credit (1.0 or 0.5)
  source       text,                             -- manual / wine-note / auto など
  decision     text,                             -- decision の場合: 休眠/廃止/変質/再点灯
  new_purpose  text,                             -- 変質の場合の新 purpose
  created_at   timestamptz default now()         -- サーバー側の記録時刻
);

-- Row Level Security 有効化
alter table star_chart_events enable row level security;

-- 自分のイベントのみ閲覧可
create policy "Users can view own events"
  on star_chart_events for select
  using (auth.uid() = user_id);

-- 自分のイベントのみ追加可
create policy "Users can insert own events"
  on star_chart_events for insert
  with check (auth.uid() = user_id);

-- （更新・削除は禁止・追記専用の哲学を DB レベルで強制）

-- インデックス（ユーザーごとの時系列取得を高速化）
create index if not exists star_chart_events_user_ts_idx
  on star_chart_events (user_id, ts desc);

create index if not exists star_chart_events_user_routine_idx
  on star_chart_events (user_id, routine_id, ts desc);

-- ============================================================
-- 完了確認クエリ（実行後、以下を確認できる）
-- ============================================================
-- select * from star_chart_events order by ts desc limit 10;
