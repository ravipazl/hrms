# 🔍 EDIT MODE PREVIEW DEBUG - STEP BY STEP TEST

## 🎯 OBJECTIVE

Find out exactly WHERE and WHEN the files are getting lost in EDIT mode preview.

---

## 📋 STEP-BY-STEP TEST

### Step 1: Open EDIT Page
1. **Open Browser Console** (F12 → Console tab)
2. **Clear console** (click the 🚫 icon)
3. **Navigate to:** `http://127.0.0.1:5173/reqfrom/151`
4. **Wait** for page to fully load

### Step 2: Check File Loading
**Look for these logs in console:**

```
================================================================================
📋 LOADING EXISTING REQUISITION DATA FOR EDIT MODE
================================================================================
🔄 STARTING FILE LOADING PROCESS...
✅ Method 1: Found jobDocuments array
   Count: 1 files
   📎 Processing file 1:
      ✅ Added: pdfbookmark_hVgyeHv (4).pdf
   ✅ Successfully loaded 1 file(s) from jobDocuments

📋 VERIFICATION - Files in _filesPreviews after loading:
   1. pdfbookmark_hVgyeHv (4).pdf (86 KB)
```

**✅ CHECKPOINT 1:** Files loaded successfully?
- [ ] YES - Files show in logs
- [ ] NO - No files loaded

**If NO:** STOP here - file loading is broken!

---

### Step 3: Check MultiFileUploadWidget Initialization
**Look for these logs:**

```
📎 MultiFileUpload initState:
   - Initial files count: 1
```

**✅ CHECKPOINT 2:** Widget received the files?
- [ ] YES - Initial files count: 1
- [ ] NO - Initial files count: 0

**If NO:** The files aren't being passed to the widget!

---

### Step 4: Check Files in Debug Box
**On the page, look for the blue DEBUG INFO box:**

```
DEBUG INFO:
Mode: upload | Files: 1
Files: pdfbookmark_hVgyeHv (4).pdf
```

**✅ CHECKPOINT 3:** Debug box shows files?
- [ ] YES - Shows "Files: 1"
- [ ] NO - Shows "Files: 0"

**If NO:** Files lost after widget initialization!

---

### Step 5: Scroll Down and Find Preview Button
**Scroll to the BOTTOM of the page**

**Find the GREEN button that says "Preview Form"**
- NOT the eye icon (👁️) next to the uploaded file
- NOT the view/download buttons
- The GREEN button at the bottom left!

---

### Step 6: Click Preview Form Button
**Click the GREEN "Preview Form" button**

**Look for these logs:**

```
👁️ PREVIEW FORM BUTTON CLICKED!
   Calling _showFormPreview()...

================================================================================
🔍 OPENING PREVIEW DIALOG
================================================================================
📊 Current State:
   - Edit Mode: true
   - Job Description Type: upload
   - Files in _filesPreviews: 1
   - Files list:
      1. pdfbookmark_hVgyeHv (4).pdf
         - Size: 86 KB
         - Type: pdf
         - isNew: false
         - isExisting: true
         - URL: http://127.0.0.1:8000/media/...
```

**✅ CHECKPOINT 4:** Preview logs show files?
- [ ] YES - "Files in _filesPreviews: 1"
- [ ] NO - "Files in _filesPreviews: 0"

**If NO:** Files are getting cleared before preview!

---

### Step 7: Check Preview Dialog Content
**Look for preview in _buildPreviewJobDescription():**

```
🔍 PREVIEW - Job Description Type: upload
🔍 PREVIEW - Files count: 1
🔍 PREVIEW - Files list:
   1. pdfbookmark_hVgyeHv (4).pdf (86 KB)
✅ PREVIEW - Showing 1 files (FORCE DISPLAY)
```

**✅ CHECKPOINT 5:** Preview method sees the files?
- [ ] YES - "Files count: 1"
- [ ] NO - "Files count: 0"

**If YES but dialog doesn't show files:** Preview rendering issue!

---

### Step 8: Check What Actually Shows
**Look at the preview dialog:**

**Does it show:**
- [ ] A) "No documents uploaded"
- [ ] B) "1 document(s) uploaded" but no file list
- [ ] C) "1 document(s) uploaded" WITH file: pdfbookmark_hVgyeHv (4).pdf
- [ ] D) No dialog at all (navigates to another page)

---

## 📊 RESULTS MATRIX

### ✅ All Checkpoints PASS
```
Checkpoint 1: ✅ Files loaded (1 file)
Checkpoint 2: ✅ Widget received files
Checkpoint 3: ✅ Debug box shows files
Checkpoint 4: ✅ Preview logs show files
Checkpoint 5: ✅ Preview method sees files
Result: Dialog should show files!
```
**If dialog STILL doesn't show files:** Preview rendering bug!

---

### ❌ Checkpoint 1 FAILS
```
Checkpoint 1: ❌ No files loaded
```
**Problem:** File loading from server is broken in EDIT mode
**Fix:** Need to fix `_loadExistingData()` method

---

### ❌ Checkpoint 2 FAILS
```
Checkpoint 1: ✅ Files loaded
Checkpoint 2: ❌ Widget received 0 files
```
**Problem:** Files not being passed to MultiFileUploadWidget
**Fix:** Need to check `initialFiles: _filesPreviews` parameter

---

### ❌ Checkpoint 3 FAILS
```
Checkpoint 1: ✅ Files loaded
Checkpoint 2: ✅ Widget received files
Checkpoint 3: ❌ Debug box shows 0 files
```
**Problem:** Files getting cleared by widget or state update
**Fix:** Need to check widget's file management

---

### ❌ Checkpoint 4 FAILS
```
Checkpoints 1-3: ✅ All pass
Checkpoint 4: ❌ Preview shows 0 files
```
**Problem:** Files cleared between page load and preview open
**Fix:** Need to check if something is clearing `_filesPreviews`

---

### ❌ Checkpoint 5 FAILS
```
Checkpoints 1-4: ✅ All pass
Checkpoint 5: ❌ Preview method sees 0 files
```
**Problem:** Files lost in preview method
**Fix:** Need to check `_buildPreviewJobDescription()`

---

## 📸 WHAT TO SHARE

Please share:

1. **Console logs** (copy ALL text from console)
2. **Checkpoint results:**
   ```
   Checkpoint 1: ✅ or ❌
   Checkpoint 2: ✅ or ❌
   Checkpoint 3: ✅ or ❌
   Checkpoint 4: ✅ or ❌
   Checkpoint 5: ✅ or ❌
   ```
3. **What shows in dialog:** A, B, C, or D from Step 8
4. **Screenshot** of:
   - Console logs
   - DEBUG INFO box
   - Preview dialog

---

## 🎯 QUICK DIAGNOSIS

**If Checkpoint 1 fails:** File loading issue → Check API response
**If Checkpoint 2 fails:** Widget not receiving files → Check initialization
**If Checkpoint 3 fails:** Widget clearing files → Check widget logic
**If Checkpoint 4 fails:** State clearing files → Check state management
**If Checkpoint 5 fails:** Preview not reading state → Check preview logic
**If ALL checkpoints pass but no files show:** UI rendering issue

---

Ready to test! Please run through ALL checkpoints and share the results! 🔍
