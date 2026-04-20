# Resume Intake Business Rules

## Approved production target

Default target key:

- `resume_intake_v1`

Current registry:

```json
{
  "resume_intake_v1": {
    "app_token": "Ft4cbSinbaxhOusgmzNcvwDUnWh",
    "table_id": "tblv3Pfr8Psw9Jr1",
    "label": "招聘进度管理 - 2025年应聘人员登记"
  }
}
```

## Business goal

When a Feishu user uploads a PDF resume, the default production action is:

1. create a candidate record in the approved Bitable target
2. upload the original PDF
3. update the created record's `附件` field with the uploaded file token

## Safe write scope

Allowed in the fixed production path:

- `feishu_bitable_app_table_record.create`
- `feishu_bitable_app_table_record.update` for attachment backfill only
- `feishu_drive_file.upload`

Disallowed in the fixed production path:

- generic app/table creation
- target inference from vague business labels
- switching targets without explicit confirmation
- direct tenant-token OpenAPI writes when user-identity Feishu tools are available

## Success criteria

- Create success + attachment success => complete success
- Create success + attachment failure => partial success
- Create failure => failed

## Runtime order

1. download or locate PDF
2. extract text from PDF
3. build conservative fields JSON
4. generate guarded create payload
5. execute create
6. upload original PDF
7. generate guarded attachment update payload
8. execute update
9. report result

## Registering a new target

Require all of the following before allowing a new target entry:

- explicit business intent
- real `app_token`
- real `table_id`
- confirmation that registration is for write routing, not for creating a new app/table

If any of the above is missing, stop and ask.
