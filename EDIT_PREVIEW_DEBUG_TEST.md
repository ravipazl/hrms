# 🧪 EDIT MODE PREVIEW DEBUG - TEST INSTRUCTIONS

## 🎯 OBJECTIVE

Test if files are showing in PREVIEW when clicking "Preview Form" button in EDIT mode, and collect debug information.

---

## 📋 TEST STEPS

### Test 1: EDIT Mode Preview

**Steps:**
1. **Open Browser Console** (F12) → Go to "Console" tab
2. **Navigate to EDIT page** for a requisition that has uploaded files
   - Example: `http://127.0.0.1:5173/reqfrom/150`
3. **Wait for page to load** completely
4. **Look at console** - You should see file loading logs:
   ```
   🔄 STARTING FILE LOADING PROCESS...
   ✅ Method 1: Found jobDocuments array
   📋 VERIFICATION - Files in _filesPreviews after loading:
      1. file1.docx (37 KB)
      2. file2.pdf (88 KB)
      3. file3.pdf (88 KB)
   ```
5. **Click "Preview Form" button**
6. **Look at console** - You should see:
   ```
   ================================================================================
   🔍 OPENING PREVIEW DIALOG
   ================================================================================
   📊 Current State:
      - Edit Mode: true
      - Job Description Type: upload
      - Files in _filesPreviews: 3
      - Files list:
         1. file1.docx
            - Size: 37 KB
            - Type: document
            - isNew: false
            - isExisting: true
            - URL: http://127.0.0.1:8000/media/...
         2. file2.pdf
         ...
   ================================================================================
   ```
7. **Check Preview Dialog** - Should show:
   ```
   Job Description
   ───────────────────────────────────
   Job Description Type: Document Upload
   Documents: 3 document(s) uploaded
   
   Uploaded Files:
     📄 file1.docx (37 KB)
     📄 file2.pdf (88 KB)
     📄 file3.pdf (88 KB)
   ```

---

## 🔍 WHAT TO CHECK

### Console Logs to Collect:

**1. File Loading (when page opens):**
```
Look for:
- "🔄 STARTING FILE LOADING PROCESS..."
- "✅ Method 1: Found jobDocuments array"
- "📋 VERIFICATION - Files in _filesPreviews after loading:"
```

**2. Preview Opening (when clicking Preview button):**
```
Look for:
- "🔍 OPENING PREVIEW DIALOG"
- "📊 Current State:"
- "Files in _filesPreviews: X"
```

**3. Preview Content (in preview method):**
```
Look for:
- "🔍 PREVIEW - Job Description Type: X"
- "🔍 PREVIEW - Files count: X"
- "✅ PREVIEW - Showing X files (FORCE DISPLAY)"
```

---

## ❓ POSSIBLE OUTCOMES

### ✅ OUTCOME 1: Files Loaded But Preview Empty

**Console shows:**
```
Files in _filesPreviews: 3  ← Files ARE loaded
🔍 PREVIEW - Files count: 3  ← Preview sees the files
```

**But Preview Dialog Shows:**
- "No documents uploaded" OR nothing

**Diagnosis:** Preview rendering issue - files are loaded but not displayed

---

### ❌ OUTCOME 2: Files NOT Loaded

**Console shows:**
```
Files in _filesPreviews: 0  ← No files loaded
⚠️ NO FILES IN _filesPreviews!
```

**Diagnosis:** File loading issue - files not being loaded from server in EDIT mode

---

### ✅ OUTCOME 3: Everything Works

**Console shows:**
```
Files in _filesPreviews: 3
✅ PREVIEW - Showing 3 files (FORCE DISPLAY)
```

**Preview Dialog Shows:**
- 3 files with icons and sizes

**Diagnosis:** ✅ No issue! Working correctly!

---

## 📸 INFORMATION TO PROVIDE

Please provide:

1. **Screenshot of Console** showing all the debug logs
2. **Screenshot of Preview Dialog** showing what's displayed (or not displayed)
3. **Copy of console text** (if possible)

**Example Console Text to Copy:**
```
[Paste the entire console output here, including:
- File loading section
- Preview opening section
- Preview content section]
```

---

## 🐛 EXPECTED BUG SCENARIOS

### Scenario A: Files loaded, but preview empty
```
📋 VERIFICATION - Files in _filesPreviews: 3  ← ✅ Loaded
🔍 OPENING PREVIEW: Files in _filesPreviews: 3  ← ✅ Still there
🔍 PREVIEW - Files count: 3  ← ✅ Preview sees them
But dialog shows: "No documents uploaded"  ← ❌ Not displayed
```
**Cause:** Preview rendering logic issue

### Scenario B: Files not loaded in EDIT mode
```
📋 VERIFICATION - Files in _filesPreviews: 0  ← ❌ Not loaded
🔍 OPENING PREVIEW: Files in _filesPreviews: 0  ← ❌ Still empty
```
**Cause:** File loading logic issue

---

## 🔧 NEXT STEPS

After collecting this information:

1. If **Scenario A** → Fix preview rendering
2. If **Scenario B** → Fix file loading in EDIT mode
3. If **Everything works** → Bug already fixed! ✅

---

**Ready to test!** 🚀

Please run the test and share the console logs + screenshots!
