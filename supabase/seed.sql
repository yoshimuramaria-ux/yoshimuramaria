-- ============================================================
--  青楓館PBL LP 用テーブル ＋ テストデータ
--  Supabase の「SQL Editor」に全部貼り付けて「Run」してください。
--  何度実行しても大丈夫です（テストデータは入れ直しになります）。
--
--  ※ 口コミ・プロジェクト説明はすべてテスト用の見本です。
--    本番前に削除する場合は、ファイル末尾の「テストデータの削除」を実行してください。
--    （消えるのはテスト用の口コミだけ。プロジェクトと本物の口コミは残ります）
-- ============================================================

-- ---------- テーブル ----------
create table if not exists public.projects (
  id          text primary key,                 -- 例: 'wajima'
  place       text not null,                    -- カードの大きな文字
  kind        text not null,                    -- 分野ラベル
  title       text not null,
  summary     text not null,
  tags        text[] not null default '{}',
  flow        text[] not null default '{}',     -- プロジェクトの流れ
  skills      text[] not null default '{}',     -- 身につく力
  theme       text not null default 't-wajima', -- カードの色（HTML側のクラス名）
  icon        text not null default 'wave',     -- wave / sun / pen / school / leaf
  sort_order  int  not null default 0,
  is_test     boolean not null default false,
  created_at  timestamptz not null default now()
);

create table if not exists public.voices (
  id          bigint generated always as identity primary key,
  name        text not null check (char_length(name) between 1 and 12),
  grade       text not null check (grade in ('1年','2年','3年')),
  project_id  text not null references public.projects(id) on delete cascade,
  body        text not null check (char_length(body) between 1 and 160),
  is_approved boolean not null default false,   -- 先生が確認してから true にする
  is_test     boolean not null default false,
  created_at  timestamptz not null default now()
);

create index if not exists voices_project_idx on public.voices (project_id, created_at desc);

-- ---------- 権限（RLS） ----------
-- 誰でも：プロジェクトと「承認済み」口コミを読める
-- 誰でも：口コミを投稿できる（ただし未承認として入るので、すぐには表示されない）
alter table public.projects enable row level security;
alter table public.voices   enable row level security;

drop policy if exists "projects are public" on public.projects;
create policy "projects are public" on public.projects
  for select using (true);

drop policy if exists "approved voices are public" on public.voices;
create policy "approved voices are public" on public.voices
  for select using (is_approved = true);

drop policy if exists "anyone can submit a voice" on public.voices;
create policy "anyone can submit a voice" on public.voices
  for insert with check (is_approved = false and is_test = false);

-- ---------- データ（入れ直し） ----------
-- プロジェクト一覧は本番でも使うので is_test = false（消さない）。
-- 本物の口コミがプロジェクトにひもづくため、projects は削除せず上書きだけします。
delete from public.voices where is_test;

insert into public.projects (id, place, kind, title, summary, tags, flow, skills, theme, icon, sort_order, is_test) values
('wajima', '輪島', '地域・防災', '輪島の「これから」を一緒に考える',
 '石川県輪島市を訪れ、地域の方の話を聞きながら、まちの未来のためにできることを考えます。',
 array['フィールドワーク','防災','インタビュー'],
 array['輪島について事前に調べ、問いを立てる','現地を訪れ、地域の方にお話をうかがう','チームで課題を整理し、アクションを企画','学内外へ発表・発信する'],
 array['傾聴力','課題発見力','企画力'], 't-wajima', 'wave', 1, false),
('okinawa', '沖縄', '平和・環境', '沖縄で、海と歴史から学ぶ',
 '沖縄の自然・文化・歴史に触れ、自分たちの暮らしとつながる問いを見つけて探究します。',
 array['探究','環境','平和学習'],
 array['沖縄の歴史・自然について事前学習','現地で見て、聞いて、感じる','気づきから探究テーマを設定','レポートやプレゼンにまとめて発表'],
 array['探究力','多角的な視点','表現力'], 't-okinawa', 'sun', 2, false),
('bunbougu', '文房具', '商品企画', '中高生が本当にほしい文房具をつくる',
 'ユーザーである自分たちの目線で、新しい文房具のアイデアを考え、企画・試作・プレゼンに挑戦します。',
 array['ものづくり','マーケティング','プレゼン'],
 array['身の回りの「不便」をリサーチ','アンケートでニーズを調べる','アイデアを出し合い試作する','企業の方に向けて提案する'],
 array['発想力','データ活用','提案力'], 't-bunbougu', 'pen', 3, false),
('ashiya', '芦屋校舎', '空間デザイン', '自分たちの校舎を、自分たちでつくる',
 '毎日過ごす芦屋校舎を「もっと学びたくなる場所」にするため、使い方や空間づくりを考えて提案します。',
 array['デザイン','合意形成','学校づくり'],
 array['校舎の使われ方を観察・調査','生徒や先生の声を集める','改善プランを考えてデザイン','学校へ提案し、実現をめざす'],
 array['デザイン思考','協働力','合意形成力'], 't-ashiya', 'school', 4, false),
('ozu', '大津町', 'まちづくり', '大津町の魅力を、もっと多くの人へ',
 '熊本県大津町をフィールドに、まちの魅力や課題を調べ、若い世代ならではの発信方法を考えます。',
 array['地域活性','発信','フィールドワーク'],
 array['大津町の特徴を調べる','現地で人やお店を取材する','魅力を伝えるコンテンツを企画・制作','まちの方へ成果を発表する'],
 array['取材力','情報発信力','行動力'], 't-ozu', 'leaf', 5, false)
on conflict (id) do update set
  place = excluded.place, kind = excluded.kind, title = excluded.title, summary = excluded.summary,
  tags = excluded.tags, flow = excluded.flow, skills = excluded.skills, theme = excluded.theme,
  icon = excluded.icon, sort_order = excluded.sort_order, is_test = excluded.is_test;

insert into public.voices (name, grade, project_id, body, is_approved, is_test) values
-- 承認済み（ページに表示される）
('H.S.', '2年', 'wajima',   '現地の方の話を直接聞いて、ニュースで見ていたことが「自分ごと」になりました。帰ってからもチームで何ができるか話し合い続けています。', true, true),
('R.K.', '1年', 'bunbougu', '自分のアイデアが試作品になったときは本当にうれしかった！企業の方からのフィードバックは厳しいけど、すごく勉強になります。', true, true),
('M.T.', '3年', 'okinawa',  'きれいな海の裏にある課題を知って、環境問題を本気で調べたくなりました。この経験が進路を考えるきっかけになりました。', true, true),
('Y.N.', '2年', 'ashiya',   '「どうせ変わらない」と思っていた校舎のことを、自分たちで提案できるのが楽しい。先生も本気で聞いてくれます。', true, true),
('K.O.', '1年', 'ozu',      '人見知りだったけど、取材でまちの人と話すうちに自然と話せるようになりました。チームの仲間とも仲良くなれた！', true, true),
('A.I.', '3年', 'wajima',   '答えがないから最初は不安でした。でも、迷いながら考えた時間こそが一番の学びだったと今は思います。', true, true),
('S.F.', '2年', 'okinawa',  '現地で聞いたお話を、クラスのみんなに伝える役をやりました。どう話せば伝わるか、何度も練習したのがいい経験です。', true, true),
('T.M.', '1年', 'bunbougu', 'アンケートを集計してみたら、思っていたのと全然ちがう結果が出てびっくり。データって大事だと実感しました。', true, true),
-- 未承認（ページには出ない。承認の流れを試す用）
('ゆう',  '1年', 'ozu',      'テスト投稿です。承認するとページに表示されます。', false, true),
('こはる', '2年', 'ashiya',  'テスト投稿その2。is_approved を true にして表示を確認してください。', false, true);

-- 確認用
select p.place, count(v.*) filter (where v.is_approved) as 表示中, count(v.*) filter (where not v.is_approved) as 未承認
from public.projects p left join public.voices v on v.project_id = p.id
group by p.place, p.sort_order order by p.sort_order;

-- ============================================================
--  テストデータの削除（本番前に、ここだけ選択して実行）
-- ------------------------------------------------------------
-- delete from public.voices where is_test;
-- ============================================================
