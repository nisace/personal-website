# Scripts

## Convert Google Doc to Quarto Markdown
The script `scripts/google_doc_to_qmd.sh` converts a Google Doc (exported as docx and HTML) into a Quarto Markdown (`.qmd`) file, handling images, equations, Google drawings and formatting appropriately.

### Usage
1. Export your Google Doc as a `.docx` file and an `.html` file.
2. Run the script with the following command:
   ```bash
   bash scripts/google_doc_to_qmd.sh path/to/document.docx path/to/document.html path/to/output_directory
   ```
3. The output `.qmd` file and associated media will be saved in the specified output directory.

### Example
The files in `data/google_doc_imports/derivatives_and_backpropagation/output` were generated using the command:
```bash
./scripts/google_doc_to_qmd.sh data/google_doc_imports/derivatives_and_backpropagation/doc.docx data/google_doc_imports/derivatives_and_backpropagation/doc.html data/google_doc_imports/derivatives_and_backpropagation/output
```
