# Kanban Flux 產品級 UI/UX 改版計畫

## Summary
把目前的三欄 kanban 從「功能可用」提升成「每日可用的工作板」。本次採完整改版：新增 priority、due date、labels 資料欄位，並重整主畫面、卡片、表單、搜尋/篩選、空狀態與錯誤/loading 體驗。資料庫變更以一份 SQL 檔交付，供手動貼到 Supabase SQL Editor 執行。

## Key Changes
- 新增資料欄位：
  - `priority text not null default 'medium'`，允許 `low | medium | high`
  - `due_date date null`
  - `labels text[] not null default '{}'`
- 更新 `Task` / `TaskModel` / data source：
  - Flutter model 新增 `priority`、`dueDate`、`labels`
  - create/update 支援完整欄位
  - 讀取舊資料時使用 fallback：priority 預設 `medium`、dueDate 為 `null`、labels 為空陣列
- 主看板 UI：
  - AppBar 下方新增工作板 summary：總任務數、進行中數、逾期數、已完成數
  - 新增搜尋列，可搜尋 title、description、labels
  - 新增篩選列：All、High priority、Due soon、Overdue
  - 三欄保留拖曳，但欄位 header 顯示數量、狀態色與更清楚的 drop 狀態
- 任務卡 UI：
  - 顯示 priority badge、due date、labels chips、建立日期
  - 過期 due date 用紅色提示，今日/即將到期用提醒色
  - 空描述不佔位，長內容保持兩行截斷
- 新增/編輯表單：
  - bottom sheet 改成完整任務表單：title、description、priority segmented control、due date picker、labels 輸入
  - labels 以逗號分隔輸入，儲存前 trim 並移除空值
  - title 必填；priority 必須是三個合法值之一
- 狀態體驗：
  - Loading 改為 skeleton 或更貼近看板的載入狀態
  - Error 加上「重試」按鈕，呼叫 `ref.invalidate(taskControllerProvider)`
  - 空看板顯示明確 CTA：建立第一張任務
  - 欄位空狀態顯示簡短提示，例如「把任務拖到這裡」

## Public Interfaces / Schema
- 新增 SQL 檔，例如 `supabase_add_task_ui_fields.sql`：
  - `alter table tasks add column if not exists priority text not null default 'medium';`
  - `alter table tasks add column if not exists due_date date;`
  - `alter table tasks add column if not exists labels text[] not null default '{}';`
  - 加上 check constraint 限制 priority 為 `low | medium | high`
- `TaskRemoteDataSource.createTask(...)` 改為接收完整 task input：title、description、priority、dueDate、labels、userId
- `TaskRemoteDataSource.updateTaskContent(...)` 同步更新 title、description、priority、dueDate、labels
- 不新增第三方 UI 套件；使用 Flutter Material 3 內建元件完成 date picker、segmented buttons、chips、menus

## Test Plan
- 跑 `flutter analyze`，必須無 issues。
- 跑 `flutter test`，既有測試必須通過。
- 新增 model 測試：
  - Supabase JSON 缺少新欄位時 fallback 正確
  - labels 從 `List<dynamic>` 正確轉成 `List<String>`
  - due_date 為 null 或 ISO date 時解析正確
- 手動驗收情境：
  - 建立含 priority、due date、labels 的任務
  - 編輯任務並清空 due date / labels
  - 搜尋 title、description、label 都能命中
  - 篩選 High priority、Due soon、Overdue 正確
  - 拖曳任務跨欄後資料刷新且 badge 保留
  - 空看板、空欄位、載入、錯誤畫面都不突兀
  - 手機寬度下可操作，不出現文字擠壓或按鈕重疊

## Assumptions
- 使用者會先在 Supabase SQL Editor 執行新增的 SQL 檔，再測試新版 Flutter app。
- `due_date` 只做到日期，不做到時間。
- labels 採文字陣列，不新增獨立 labels table。
- priority 預設為 `medium`。
- 這次聚焦 kanban 主體與任務表單，不重做登入頁視覺。
