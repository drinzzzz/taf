# ProjectMate API Routes & Dead Code Analysis Report

**Generated:** 2026-06-05  
**Codebase:** /www/wwwroot/project_mate  
**Total Router Files:** 31 (all mounted in main.py)  
**Total API Endpoints:** ~165 routes

---

## A) All API Routes by Module

### 1. admin_api.py (6 routes)
| Method | Path | Function |
|--------|------|----------|
| GET | `/api/admin/users` | `admin_list_users` |
| POST | `/api/admin/users` | `admin_add_user` |
| PUT | `/api/admin/users/{user_id}` | `admin_update_user` |
| DELETE | `/api/admin/users/{user_id}` | `admin_delete_user` |
| GET | `/api/admin/config` | `admin_get_config` |
| PUT | `/api/admin/config` | `admin_update_config` |

### 2. audit_logs_api.py (2 routes)
| Method | Path | Function |
|--------|------|----------|
| GET | `/api/audit-logs` | `api_audit_logs` |
| GET | `/api/audit-logs/recent` | `api_recent_activities` |

### 3. auth.py (12 routes)
| Method | Path | Function |
|--------|------|----------|
| GET | `/api/auth/status` | `auth_status` |
| POST | `/api/auth/register` | `register` |
| POST | `/api/auth/login` | `login` |
| POST | `/api/auth/debug-login` | `debug_login` |
| POST | `/api/auth/token/validate` | `validate_token` |
| POST | `/api/auth/logout` | `logout` |
| GET | `/api/auth/profile` | `get_profile` |
| POST | `/api/auth/switch-user` | `switch_user` |
| PUT | `/api/auth/profile` | `update_profile` |
| POST | `/api/auth/change-password` | `change_password` |
| GET | `/api/auth/users` | `list_users` |
| PUT | `/api/auth/users/{user_id}` | `admin_update_user` |

### 4. contracts.py (11 routes)
| Method | Path | Function |
|--------|------|----------|
| GET | `/api/projects/{project_id}/contracts` | `api_list_contracts` |
| POST | `/api/projects/{project_id}/contracts` | `api_create_contract` |
| GET | `/api/contracts` | `api_list_all_contracts` |
| GET | `/api/contracts/tree` | `api_contract_tree` |
| GET | `/api/contracts/serve-file` | `api_serve_contract_file` |
| GET | `/api/contracts/{cid}` | `api_get_contract` |
| GET | `/api/contracts/{cid}/nutstore-files` | `api_contract_nutstore` |
| POST | `/api/contracts` | `api_create_contract_json` |
| PUT | `/api/contracts/{cid}` | `api_update_contract` |
| DELETE | `/api/contracts/{cid}` | `api_delete_contract` |

### 5. crm.py (14 routes)
| Method | Path | Function |
|--------|------|----------|
| GET | `/api/crm/stats` | `api_crm_stats` |
| GET | `/api/crm/clients` | `api_list_clients` |
| GET | `/api/crm/clients/{client_id}` | `api_get_client` |
| POST | `/api/crm/clients` | `api_create_client` |
| PUT | `/api/crm/clients/{client_id}` | `api_update_client` |
| DELETE | `/api/crm/clients/{client_id}` | `api_delete_client` |
| GET | `/api/crm/contacts` | `api_list_contacts` |
| GET | `/api/crm/contacts/{contact_id}` | `api_get_contact` |
| POST | `/api/crm/contacts` | `api_create_contact` |
| PUT | `/api/crm/contacts/{contact_id}` | `api_update_contact` |
| DELETE | `/api/crm/contacts/{contact_id}` | `api_delete_contact` |
| POST | `/api/crm/links` | `api_link_contact` |
| DELETE | `/api/crm/links` | `api_unlink_contact` |
| GET | `/api/crm/greetings/upcoming` | `api_upcoming_greetings` |
| POST | `/api/crm/greetings` | `api_create_greeting` |
| PUT | `/api/crm/greetings/{greeting_id}` | `api_update_greeting` |

### 6. dashboard.py (1 route)
| Method | Path | Function |
|--------|------|----------|
| GET | `/api/dashboard/stats` | `dashboard_stats` |

### 7. data_import_api.py (2 routes)
| Method | Path | Function |
|--------|------|----------|
| GET | `/api/export/{entity}/template` | `download_template` |
| POST | `/api/import/{entity}` | `import_data` |

### 8. export_api.py (2 routes)
| Method | Path | Function |
|--------|------|----------|
| GET | `/api/transactions/export` | `export_transactions` |
| GET | `/api/invoices/export` | `export_invoices` |

### 9. files_api.py (5 routes)
| Method | Path | Function |
|--------|------|----------|
| GET | `/api/projects/{project_id}/files` | `list_files` |
| POST | `/api/projects/{project_id}/files` | `upload_file` |
| GET | `/api/files/{file_id}/download` | `download_file` |
| DELETE | `/api/files/{file_id}` | `delete_file` |
| GET | `/api/file-categories` | `file_categories` |

### 10. frontend_logs.py (3 routes)
| Method | Path | Function |
|--------|------|----------|
| POST | `/api/logs/frontend-error` | `report_frontend_error` |
| GET | `/api/logs/frontend-errors` | `list_frontend_errors` |
| GET | `/api/logs/frontend-stats` | `frontend_error_stats` |

### 11. invoices.py (6 routes)
| Method | Path | Function |
|--------|------|----------|
| GET | `/api/invoices/stats` | `api_invoice_stats` |
| GET | `/api/invoices` | `api_list_invoices` |
| POST | `/api/invoices` | `api_create_invoice` |
| GET | `/api/invoices/{invoice_id}` | `api_get_invoice` |
| PUT | `/api/invoices/{invoice_id}` | `api_update_invoice` |
| DELETE | `/api/invoices/{invoice_id}` | `api_delete_invoice` |

### 12. leads.py (5 routes)
| Method | Path | Function |
|--------|------|----------|
| GET | `/api/leads` | `api_list_leads` |
| GET | `/api/leads/stages` | `api_leads_stages` |
| PUT | `/api/leads/{lead_id}/advance` | `api_advance_lead` |
| PUT | `/api/leads/{lead_id}/convert` | `api_convert_lead` |
| PUT | `/api/leads/{lead_id}/lose` | `api_lose_lead` |

### 13. meetings.py (2 routes)
| Method | Path | Function |
|--------|------|----------|
| GET | `/api/meetings` | `api_list_meetings` |
| POST | `/api/meetings` | `api_create_meeting` |

### 14. memos.py (4 routes)
| Method | Path | Function |
|--------|------|----------|
| GET | `/api/memos` | `api_list_memos` |
| POST | `/api/memos` | `api_create_memo` |
| PUT | `/api/memos/{order_id}` | `api_update_memo` |
| DELETE | `/api/memos/{order_id}` | `api_delete_memo` |

### 15. nav_config.py (2 routes)
| Method | Path | Function |
|--------|------|----------|
| GET | `/api/nav/config` | `get_nav_config` |
| POST | `/api/nav/config` | `save_nav_config` |

### 16. notifications_api.py (6 routes)
| Method | Path | Function |
|--------|------|----------|
| GET | `/api/notifications` | `api_get_notifications` |
| GET | `/api/notifications/unread-count` | `api_unread_count` |
| PUT | `/api/notifications/{notif_id}/read` | `api_mark_read` |
| PUT | `/api/notifications/read-all` | `api_mark_all_read` |
| DELETE | `/api/notifications/{notif_id}` | `api_delete_notif` |
| POST | `/api/notifications/check-alerts` | `api_check_alerts` |

### 17. nutstore.py (5 routes)
| Method | Path | Function |
|--------|------|----------|
| GET | `/api/nutstore/links` | `api_list_nutstore_links` |
| POST | `/api/nutstore/scan` | `api_scan_nutstore` |
| GET | `/api/nutstore/project/{project_id}` | `api_project_nutstore` |
| GET | `/api/nutstore/summary` | `api_nutstore_summary` |
| GET | `/api/nutstore/recent-files` | `api_nutstore_recent_files` |

### 18. platform_admin_api.py (9 active routes)
| Method | Path | Function |
|--------|------|----------|
| POST | `/api/platform/auth/login` | `platform_login` |
| GET | `/api/platform/tenants` | `platform_list_tenants` |
| POST | `/api/platform/tenants/{tenant_id}/suspend` | `platform_suspend_tenant` |
| POST | `/api/platform/tenants/{tenant_id}/activate` | `platform_activate_tenant` |
| GET | `/api/platform/audit-logs` | `platform_list_audit_logs` |
| POST | `/api/platform/tenants/{tenant_id}/auto-renew` | `platform_set_auto_renew` |
| GET | `/api/platform/expiring` | `platform_list_expiring` |
| POST | `/api/platform/tenants/{tenant_id}/renew` | `platform_renew_tenant` |

**Archived (commented out):** 6 routes for subscription management, tenant creation, and super-admin browsing

### 19. project_access.py (7 routes)
| Method | Path | Function |
|--------|------|----------|
| GET | `/api/access/users` | `api_get_users` |
| GET | `/api/access/projects` | `api_get_projects` |
| GET | `/api/access/user/{user_id}` | `api_get_user_access` |
| GET | `/api/access/project/{project_id}` | `api_get_project_access` |
| POST | `/api/access/user/{user_id}` | `api_batch_set_user_access` |
| POST | `/api/access/project/{project_id}` | `api_batch_set_project_users` |
| DELETE | `/api/access/user/{user_id}/project/{project_id}` | `api_remove_single_access` |

### 20. project_contacts.py (6 routes)
| Method | Path | Function |
|--------|------|----------|
| GET | `/api/project-contacts` | `api_list_project_contacts` |
| GET | `/api/project-contacts/{contact_id}` | `api_get_contact` |
| POST | `/api/project-contacts` | `api_create_contact` |
| PUT | `/api/project-contacts/{contact_id}` | `api_update_contact` |
| POST | `/api/projects/{project_id}/project-contacts` | `api_link_contact` |
| GET | `/api/projects/{project_id}/project-contacts` | `api_project_contacts` |

### 21. project_export.py (1 route)
| Method | Path | Function |
|--------|------|----------|
| GET | `/api/projects/export` | `export_projects` |

### 22. projects.py (6 routes)
| Method | Path | Function |
|--------|------|----------|
| GET | `/api/projects` | `api_list_projects` |
| POST | `/api/projects` | `api_create_project` |
| GET | `/api/projects/{project_id}` | `api_get_project` |
| PUT | `/api/projects/{project_id}` | `api_update_project` |
| DELETE | `/api/projects/{project_id}` | `api_delete_project` |
| GET | `/api/pipeline/summary` | `pipeline_summary` |
| GET | `/api/leads/summary` | `pipeline_summary` (alias) |

### 23. quotations.py (6 routes)
| Method | Path | Function |
|--------|------|----------|
| GET | `/api/quotations` | `api_list_quotation` |
| GET | `/api/quotations/versions` | `api_list_versions` |
| GET | `/api/quotations/versions/{version_id}` | `api_get_version` |
| POST | `/api/quotations/versions` | `api_create_version` |
| GET | `/api/quotations/changes` | `api_list_changes` |
| GET | `/api/quotations/settlement` | `api_get_settlement` |

### 24. schedules.py (12 routes)
| Method | Path | Function |
|--------|------|----------|
| GET | `/api/schedules` | `api_get_schedule` |
| POST | `/api/schedules` | `api_save_schedule` |
| GET | `/api/schedules/summary` | `api_schedule_summary` |
| GET | `/api/schedules/timeline` | `api_get_timeline` |
| GET | `/api/schedules/events` | `api_list_events` |
| POST | `/api/schedules/events` | `api_add_event` |
| PUT | `/api/schedules/events/{event_id}` | `api_update_event` |
| DELETE | `/api/schedules/events/{event_id}` | `api_delete_event` |
| GET | `/api/schedules/milestones` | `api_get_milestones` |
| POST | `/api/schedules/milestones` | `api_add_milestone` |
| PUT | `/api/schedules/milestones/{milestone_id}` | `api_update_milestone` |
| DELETE | `/api/schedules/milestones/{milestone_id}` | `api_delete_milestone` |

### 25. search_api.py (1 route)
| Method | Path | Function |
|--------|------|----------|
| GET | `/api/search/global` | `global_search` |

### 26. subscription_api.py (6 routes)
| Method | Path | Function |
|--------|------|----------|
| GET | `/api/subscription/plans` | `list_plans` |
| GET | `/api/subscription/{slug}/status` | `get_subscription_status` |
| POST | `/api/subscription/{slug}/upgrade` | `upgrade_plan` |
| POST | `/api/subscription/{slug}/renew` | `renew_subscription` |
| GET | `/api/subscription/{slug}/history` | `get_billing_history` |

### 27. suppliers.py (17 routes)
| Method | Path | Function |
|--------|------|----------|
| POST | `/api/suppliers/verify-pin` | `api_verify_cost_pin` |
| GET | `/api/suppliers` | `api_list_suppliers` |
| GET | `/api/suppliers/{supplier_id}` | `api_get_supplier` |
| POST | `/api/suppliers` | `api_create_supplier` |
| PUT | `/api/suppliers/{supplier_id}` | `api_update_supplier` |
| DELETE | `/api/suppliers/{supplier_id}` | `api_delete_supplier` |
| GET | `/api/subcontractors` | `api_list_subcontractors` |
| GET | `/api/subcontractors/{sub_id}` | `api_get_subcontractor` |
| POST | `/api/subcontractors` | `api_create_subcontractor` |
| PUT | `/api/subcontractors/{sub_id}` | `api_update_subcontractor` |
| DELETE | `/api/subcontractors/{sub_id}` | `api_delete_subcontractor` |
| GET | `/api/projects/{project_id}/subcontractors` | `api_project_subcontractors` |
| POST | `/api/projects/{project_id}/subcontractors` | `api_link_subcontractor` |
| PUT | `/api/subcontractor-links/{link_id}` | `api_update_link` |
| GET | `/api/projects/{project_id}/subcontractors/summary` | `api_subcontractor_summary` |
| GET | `/api/subcontractor-settlements` | `api_list_settlements` |
| POST | `/api/subcontractor-settlements` | `api_add_settlement` |

### 28. system_config.py (2 routes)
| Method | Path | Function |
|--------|------|----------|
| GET | `/api/system/config` | `get_config` |
| PUT | `/api/system/config` | `update_config` |

### 29. tasks.py (4 routes)
| Method | Path | Function |
|--------|------|----------|
| GET | `/api/tasks/today` | `api_get_today_tasks` |
| GET | `/api/tasks/date` | `api_get_tasks_by_date` |
| POST | `/api/tasks` | `api_create_task` |
| PUT | `/api/tasks/{task_id}` | `api_update_task` |

### 30. tenant_api.py (2 routes)
| Method | Path | Function |
|--------|------|----------|
| GET | `/api/tenant/my-tenant` | `get_my_tenant` |
| GET | `/api/tenant/{slug}/status` | `get_tenant_status` |

### 31. transactions.py (2 routes)
| Method | Path | Function |
|--------|------|----------|
| GET | `/api/transactions` | `api_list_transactions` |
| POST | `/api/transactions` | `api_create_transaction` |

---

## B) Dead Code Candidates

### 🔴 Dead Services (Not Imported by Any Router)

| Service File | Status | Notes |
|--------------|--------|-------|
| `services/conversation_service.py` | **DEAD** | 7KB file, not imported anywhere. Likely legacy WeChat conversation handling. |

### ✅ Active Services (All Used)

| Service | Used By |
|---------|---------|
| `audit_service.py` | audit_logs_api.py |
| `auth_service.py` | auth.py, platform_admin_api.py, project_access.py |
| `contact_sync.py` | project_contacts.py |
| `crm_service.py` | crm.py |
| `invoice_service.py` | invoices.py, export_api.py |
| `meeting_service.py` | meetings.py |
| `memo_service.py` | memos.py |
| `notification_service.py` | notifications_api.py |
| `nutstore_service.py` | nutstore.py |
| `project_access_service.py` | contracts.py, dashboard.py, invoices.py, leads.py, meetings.py, memos.py, projects.py, project_access.py, project_export.py, quotations.py, schedules.py, suppliers.py, tasks.py, transactions.py |
| `project_service.py` | leads.py, project_access.py, project_export.py, projects.py |
| `quotation_service.py` | quotations.py |
| `schedule_service.py` | schedules.py |
| `supplier_service.py` | suppliers.py |
| `task_service.py` | tasks.py |
| `transaction_service.py` | transactions.py, export_api.py |

### 🟡 Archived/Commented Code in Routers

| Router File | Archived Routes | Notes |
|-------------|-----------------|-------|
| `platform_admin_api.py` | 6 routes | Subscription management, tenant creation, super-admin browsing (single-tenant mode) |
| `export_api.py` | 1 route | `export_workorders` - workorders module archived |

### ✅ Frontend Routes - All Views Are Routed

| View File | Route Path | Status |
|-----------|------------|--------|
| `Login.vue` | `/login` | ✅ Routed |
| `Dashboard.vue` | `/dashboard` | ✅ Routed |
| `ProjectList.vue` | `/projects` | ✅ Routed |
| `ProjectDetail.vue` | `/projects/:id` | ✅ Routed |
| `ContractList.vue` | `/contracts` | ✅ Routed |
| `Quotation.vue` | `/quotation` | ✅ Routed |
| `Schedule.vue` | `/schedule` | ✅ Routed |
| `Leads.vue` | `/leads` | ✅ Routed |
| `Memos.vue` | `/memos` | ✅ Routed |
| `Crm.vue` | `/crm` | ✅ Routed |
| `Settings.vue` | `/settings` | ✅ Routed |
| `Admin.vue` | `/admin` | ✅ Routed |

**No dead frontend pages found.** All view files have corresponding routes.

### 📋 Feature Flags Status (from config.py)

| Feature | Flag Status | Router Coverage |
|---------|-------------|-----------------|
| memos | ✅ Enabled | memos.py (4 routes) |
| suppliers | ✅ Enabled | suppliers.py (17 routes) |
| meetings | ✅ Enabled | meetings.py (2 routes) |
| crm | ✅ Enabled | crm.py (14 routes) |
| deliverables | ❌ Disabled | No router (expected) |
| kanban | ✅ Enabled | Part of projects.py |

---

## C) Summary Statistics

| Category | Count |
|----------|-------|
| **Total Router Files** | 31 |
| **Total API Endpoints** | ~165 |
| **Dead Services** | 1 (`conversation_service.py`) |
| **Dead Router Files** | 0 |
| **Dead Frontend Pages** | 0 |
| **Archived Routes (commented)** | 7 |

---

## D) Recommendations

1. **Remove `conversation_service.py`** - This 7KB service file is completely unused. Safe to delete.

2. **Clean up archived code** - Consider removing the commented-out routes in:
   - `platform_admin_api.py` (6 archived multi-tenant routes)
   - `export_api.py` (1 archived workorders export)

3. **All router files are properly mounted** - No dead router files found.

4. **Frontend is clean** - All view components have corresponding routes.

5. **Service layer is healthy** - Only 1 dead service out of 16 total service files.

---

**Report complete.** The codebase is in good shape with minimal dead code (only 1 unused service file).
