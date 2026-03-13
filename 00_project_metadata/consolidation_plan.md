# Plan: Merge and Refine HTML Guides

Consolidate `modeling_guide.html` and `repository_usage_guide.html` into a single, comprehensive master document to eliminate redundancy and improve accessibility.

## Proposed Strategy

1.  **Refine `modeling_guide.html`**:
    *   Rename the title to "Technical Manual: Bhutan CMIP6 BIOCLIM v1.0".
    *   Adopt the modern, cleaner "hero" and "chip" styling from `repository_usage_guide.html`.
    *   Integrate the **Canonical Folder Map** and **Primary Workflows** (R/PowerShell commands) from the usage guide.
    *   Retain and polish the **Scientific Protocol** (BIOCLIM variables, Ensemble theory, SSP scenarios, VIF selection).
    *   Include the **Validation Checklist** and **File Naming Convention** for technical users.
    *   Ensure the **APA 7 Citation** and **Wangdi Wangdi** affiliation are prominently displayed.
2.  **Delete `repository_usage_guide.html`**:
    *   Once the content is successfully merged and verified, remove the redundant file to clean up the `00_project_metadata/` directory.
3.  **Update `00_project_metadata/readme.md`**:
    *   Remove the reference to the deleted file.

## Verification Steps
- Open the updated `modeling_guide.html` to ensure all styling and links work correctly.
- Verify that no information from the usage guide was lost during the merge.
- Confirm the redundant file is deleted.
