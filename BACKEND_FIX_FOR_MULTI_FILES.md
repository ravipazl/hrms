# 🔧 Backend Fix for Multi-File Upload

## 🔴 PROBLEM IDENTIFIED

**API Response shows:**
```json
{
  "job_documents": [],  // ❌ EMPTY!
  "job_document": null,
  "job_document_url": null
}
```

**Frontend is sending files correctly with field name:** `'job_documents'`

**Backend is NOT:**
1. ❌ Receiving the files
2. ❌ Saving files to filesystem
3. ❌ Creating JSON array with file metadata
4. ❌ Storing JSON in database

---

## ✅ SOLUTION: Backend Django Code

### 1. **Update Django Model** (`models.py`)

```python
from django.db import models
from django.core.files.storage import default_storage
import json

class Requisition(models.Model):
    # ... existing fields ...
    
    job_description = models.TextField(blank=True, null=True)
    job_description_type = models.CharField(
        max_length=10,
        choices=[('text', 'Text'), ('upload', 'Upload')],
        default='text'
    )
    
    # NEW: Store multiple documents as JSON
    job_documents = models.JSONField(blank=True, null=True, default=list)
    
    # Legacy fields (keep for backward compatibility)
    job_document = models.CharField(max_length=500, blank=True, null=True)
    job_document_url = models.URLField(blank=True, null=True)
    
    # ... other fields ...
```

### 2. **Update Serializer** (`serializers.py`)

```python
from rest_framework import serializers
from .models import Requisition

class RequisitionSerializer(serializers.ModelSerializer):
    # Add file upload fields
    job_documents_files = serializers.ListField(
        child=serializers.FileField(),
        write_only=True,
        required=False,
        allow_empty=True
    )
    
    class Meta:
        model = Requisition
        fields = '__all__'
        extra_fields = ['job_documents_files']
    
    def create(self, validated_data):
        # Extract uploaded files
        uploaded_files = validated_data.pop('job_documents_files', [])
        
        # Create requisition
        requisition = Requisition.objects.create(**validated_data)
        
        # Process and save files
        if uploaded_files:
            job_documents = []
            for file in uploaded_files:
                # Save file to media directory
                file_path = default_storage.save(
                    f'job_documents/{file.name}',
                    file
                )
                
                # Get full URL
                file_url = default_storage.url(file_path)
                
                # Add to JSON array
                job_documents.append({
                    'name': file.name,
                    'path': file_path,
                    'url': file_url,
                    'size': file.size,
                    'type': self._get_file_type(file.name)
                })
            
            # Save JSON to database
            requisition.job_documents = job_documents
            requisition.save()
        
        return requisition
    
    def update(self, instance, validated_data):
        # Extract uploaded files
        new_files = validated_data.pop('job_documents_files', [])
        existing_files = validated_data.pop('existing_files', None)
        
        # Update basic fields
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        
        # Handle files
        if new_files or existing_files is not None:
            job_documents = []
            
            # Keep existing files if provided
            if existing_files and isinstance(existing_files, str):
                try:
                    job_documents = json.loads(existing_files)
                except:
                    job_documents = []
            elif existing_files and isinstance(existing_files, list):
                job_documents = existing_files
            elif instance.job_documents:
                job_documents = instance.job_documents
            
            # Add new files
            for file in new_files:
                file_path = default_storage.save(
                    f'job_documents/{file.name}',
                    file
                )
                file_url = default_storage.url(file_path)
                
                job_documents.append({
                    'name': file.name,
                    'path': file_path,
                    'url': file_url,
                    'size': file.size,
                    'type': self._get_file_type(file.name)
                })
            
            instance.job_documents = job_documents
        
        instance.save()
        return instance
    
    def _get_file_type(self, filename):
        """Determine file type from extension"""
        ext = filename.split('.')[-1].lower()
        if ext == 'pdf':
            return 'pdf'
        elif ext in ['jpg', 'jpeg', 'png', 'gif']:
            return 'image'
        else:
            return 'document'
```

### 3. **Update View** (`views.py`)

```python
from rest_framework import viewsets
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from .models import Requisition
from .serializers import RequisitionSerializer

class RequisitionViewSet(viewsets.ModelViewSet):
    queryset = Requisition.objects.all()
    serializer_class = RequisitionSerializer
    
    # IMPORTANT: Add parsers to handle file uploads
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    
    def create(self, request, *args, **kwargs):
        print("📥 Received CREATE request")
        print(f"📎 Files: {request.FILES}")
        print(f"📋 Data: {request.data}")
        
        # Extract multiple files from 'job_documents' field
        files = request.FILES.getlist('job_documents')
        print(f"📎 Extracted {len(files)} files from job_documents field")
        
        # Create mutable copy of request data
        data = request.data.copy()
        
        # Add files to data
        if files:
            data['job_documents_files'] = files
            print(f"✅ Added {len(files)} files to serializer data")
        
        serializer = self.get_serializer(data=data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    
    def update(self, request, *args, **kwargs):
        print("📥 Received UPDATE request")
        print(f"📎 Files: {request.FILES}")
        print(f"📋 Data: {request.data}")
        
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        
        # Extract multiple files
        files = request.FILES.getlist('job_documents')
        print(f"📎 Extracted {len(files)} files from job_documents field")
        
        # Create mutable copy
        data = request.data.copy()
        
        # Add files to data
        if files:
            data['job_documents_files'] = files
            print(f"✅ Added {len(files)} files to serializer data")
        
        # Handle existing files metadata
        if 'existing_files' in request.data:
            existing_files = request.data.get('existing_files')
            if isinstance(existing_files, str):
                try:
                    data['existing_files'] = json.loads(existing_files)
                except:
                    data['existing_files'] = []
            else:
                data['existing_files'] = existing_files
        
        serializer = self.get_serializer(
            instance,
            data=data,
            partial=partial
        )
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        
        return Response(serializer.data)
```

### 4. **Update URL Configuration** (`urls.py`)

```python
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import RequisitionViewSet

router = DefaultRouter()
router.register(r'requisition', RequisitionViewSet, basename='requisition')

urlpatterns = [
    path('api/', include(router.urls)),
]
```

### 5. **Update Settings** (`settings.py`)

```python
# Media files configuration
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

# Create media directory if it doesn't exist
os.makedirs(os.path.join(MEDIA_ROOT, 'job_documents'), exist_ok=True)

# File upload settings
FILE_UPLOAD_MAX_MEMORY_SIZE = 5242880  # 5MB
DATA_UPLOAD_MAX_MEMORY_SIZE = 5242880  # 5MB
```

---

## 🧪 TESTING THE BACKEND

### Test 1: Check if Backend Receives Files

Add this to your view:

```python
def create(self, request, *args, **kwargs):
    # DEBUG: Print everything
    print("=" * 80)
    print("📥 CREATE REQUEST RECEIVED")
    print("=" * 80)
    print(f"📎 FILES: {request.FILES}")
    print(f"📎 FILES.getlist('job_documents'): {request.FILES.getlist('job_documents')}")
    print(f"📋 DATA: {request.data}")
    print(f"📋 Content-Type: {request.content_type}")
    print("=" * 80)
    
    # Rest of your code...
```

**Expected Output:**
```
================================================================================
📥 CREATE REQUEST RECEIVED
================================================================================
📎 FILES: <MultiValueDict: {'job_documents': [<InMemoryUploadedFile: file1.pdf>, <InMemoryUploadedFile: file2.doc>]}>
📎 FILES.getlist('job_documents'): [<InMemoryUploadedFile: file1.pdf>, <InMemoryUploadedFile: file2.doc>]
📋 DATA: {...}
📋 Content-Type: multipart/form-data
================================================================================
```

### Test 2: Check Database After Save

```python
# After saving
print(f"✅ Saved requisition {requisition.id}")
print(f"📎 job_documents field: {requisition.job_documents}")
print(f"📎 Number of documents: {len(requisition.job_documents or [])}")
```

---

## 🔍 FRONTEND DEBUGGING

Add this to your Flutter `requisition_api_service.dart`:

```dart
// In createRequisition method, after adding files:
print('🔍 DEBUGGING MULTIPART REQUEST:');
print('   - Total files added: ${request.files.length}');
print('   - Files:');
for (var file in request.files) {
  print('      * Field: ${file.field}');
  print('        Filename: ${file.filename}');
  print('        Length: ${file.length} bytes');
}
print('   - Fields:');
request.fields.forEach((key, value) {
  print('      * $key: ${value.length > 100 ? value.substring(0, 100) + "..." : value}');
});
```

---

## 🎯 QUICK CHECKLIST

**Backend Checklist:**
- [ ] Django model has `job_documents = JSONField(default=list)`
- [ ] Serializer has `job_documents_files` field
- [ ] View has `parser_classes = [MultiPartParser, FormParser, JSONParser]`
- [ ] View extracts files with `request.FILES.getlist('job_documents')`
- [ ] Files are saved to `media/job_documents/` directory
- [ ] JSON array is populated and saved to database
- [ ] API response includes `job_documents` array

**Frontend Checklist:**
- [ ] Files sent with field name `'job_documents'` ✅
- [ ] Using `MultipartRequest` for file uploads ✅
- [ ] Headers include `Content-Type: multipart/form-data` ✅
- [ ] Files added with `request.files.add()` ✅

---

## 📊 EXPECTED API RESPONSE AFTER FIX

```json
{
  "id": 147,
  "job_documents": [
    {
      "name": "job_description.pdf",
      "path": "/media/job_documents/job_description.pdf",
      "url": "http://127.0.0.1:8000/media/job_documents/job_description.pdf",
      "size": 245760,
      "type": "pdf"
    },
    {
      "name": "requirements.docx",
      "path": "/media/job_documents/requirements.docx",
      "url": "http://127.0.0.1:8000/media/job_documents/requirements.docx",
      "size": 102400,
      "type": "document"
    }
  ],
  // ... other fields ...
}
```

---

## 🚨 COMMON ISSUES

### Issue 1: Backend receives empty FILES
**Cause:** Missing `MultiPartParser` in view
**Fix:** Add `parser_classes = [MultiPartParser, FormParser, JSONParser]`

### Issue 2: Files save but JSON is empty
**Cause:** Not calling `requisition.save()` after updating `job_documents`
**Fix:** Always call `instance.save()` after modifying `job_documents`

### Issue 3: Can't access uploaded files
**Cause:** MEDIA_URL not configured or media files not served
**Fix:** Add to `urls.py`:
```python
from django.conf import settings
from django.conf.urls.static import static

urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
```

---

## 📞 SUPPORT

If backend still doesn't work after implementing this:

1. **Check Django logs** for errors
2. **Print `request.FILES`** to see if files are received
3. **Check file permissions** on media directory
4. **Verify MEDIA_ROOT** path exists
5. **Check database** - does `job_documents` column exist?

---

**Frontend is ✅ WORKING CORRECTLY**
**Backend needs ⚠️ IMPLEMENTATION**

Once backend is fixed, the frontend will automatically work! 🚀
