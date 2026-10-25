# Art generate-then-curate pipeline

1. **Placeholder** – every card starts with `art_status=placeholder` and an `art_assets` row (`tool`, date, license notes).  
2. **Candidate** – generate originals (approved AI workflow or human art). Record tool, date, license terms. Never scrape copyright art.  
3. **Curate** – human review rejects lookalikes and unsafe content.  
4. **Publish** – admin `POST /api/admin/cards/{code}/art/publish` sets asset + card to `published` and writes `admin_audit_logs`.  

Commercial use requires an explicit license ledger entry before store release.
