#!/usr/bin/env python
"""
Automated script to update authentication in all requisition API views
This will enable proper SessionAuthentication and IsAuthenticated permissions
"""
import re
from pathlib import Path

print("=" * 80)
print("🔐 AUTHENTICATION UPDATE SCRIPT")
print("=" * 80)
print()

# Define file paths relative to script location
BASE_DIR = Path(__file__).resolve().parent.parent / 'srmc_horilla'
FILES_TO_UPDATE = [
    BASE_DIR / 'horilla_api' / 'api_views' / 'requisition' / 'views.py',
    BASE_DIR / 'horilla_api' / 'api_views' / 'requisition' / 'enhanced_views.py',
    BASE_DIR / 'horilla_api' / 'api_views' / 'requisition' / 'workflow_status_views.py',
]

def update_file_authentication(file_path):
    """
    Update a single file to enable authentication
    
    Changes:
    1. Add SessionAuthentication import
    2. Replace permission_classes = [AllowAny] with proper authentication
    """
    if not file_path.exists():
        print(f"⚠️  File not found: {file_path}")
        return False
    
    print(f"📄 Processing: {file_path.name}")
    
    try:
        # Read file content
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Step 1: Add SessionAuthentication import if not present
        if 'from rest_framework.authentication import SessionAuthentication' not in content:
            import_pattern = r'from rest_framework\.permissions import IsAuthenticated, AllowAny'
            import_replacement = 'from rest_framework.authentication import SessionAuthentication\nfrom rest_framework.permissions import IsAuthenticated, AllowAny'
            
            if re.search(import_pattern, content):
                content = re.sub(import_pattern, import_replacement, content)
                print("  ✅ Added SessionAuthentication import")
            else:
                print("  ⚠️  Could not find permissions import to update")
        else:
            print("  ℹ️  SessionAuthentication import already present")
        
        # Step 2: Replace all permission_classes = [AllowAny] with authentication
        # Pattern matches: permission_classes = [AllowAny]  # optional comment
        permission_pattern = r'permission_classes = \[AllowAny\](?:\s*#[^\n]*)?'
        permission_replacement = '''# ✅ AUTHENTICATION ENABLED
    authentication_classes = [SessionAuthentication]
    permission_classes = [IsAuthenticated]'''
        
        matches = re.findall(permission_pattern, content)
        if matches:
            content = re.sub(permission_pattern, permission_replacement, content)
            print(f"  ✅ Updated {len(matches)} permission_classes declaration(s)")
        else:
            print("  ℹ️  No permission_classes = [AllowAny] found")
        
        # Step 3: Write back if changes were made
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"  ✅ File updated successfully")
            return True
        else:
            print("  ℹ️  No changes needed")
            return False
    
    except Exception as e:
        print(f"  ❌ Error updating file: {e}")
        return False

def main():
    """Main function to update all files"""
    updated_files = []
    skipped_files = []
    error_files = []
    
    print("Starting authentication updates...\n")
    
    for file_path in FILES_TO_UPDATE:
        result = update_file_authentication(file_path)
        
        if result is True:
            updated_files.append(file_path.name)
        elif result is False:
            if file_path.exists():
                skipped_files.append(file_path.name)
            else:
                error_files.append(file_path.name)
        
        print()  # Empty line between files
    
    # Print summary
    print("=" * 80)
    print("📊 SUMMARY")
    print("=" * 80)
    print()
    
    if updated_files:
        print(f"✅ Files updated ({len(updated_files)}):")
        for file in updated_files:
            print(f"   - {file}")
        print()
    
    if skipped_files:
        print(f"ℹ️  Files skipped (no changes needed) ({len(skipped_files)}):")
        for file in skipped_files:
            print(f"   - {file}")
        print()
    
    if error_files:
        print(f"❌ Files with errors ({len(error_files)}):")
        for file in error_files:
            print(f"   - {file}")
        print()
    
    print("=" * 80)
    print("🎯 NEXT STEPS")
    print("=" * 80)
    print()
    print("1. ✅ Update URL configuration:")
    print("   File: horilla_api/api_urls/requisition/urls.py")
    print("   Add: GetCSRFTokenView and CheckAuthenticationView URLs")
    print()
    print("2. ✅ Update Django settings:")
    print("   File: horilla/settings.py")
    print("   Add: CORS and session configuration")
    print()
    print("3. ✅ Restart Django server:")
    print("   Command: python manage.py runserver")
    print()
    print("4. ✅ Test authentication:")
    print("   - Unauthenticated: Should return 401")
    print("   - Authenticated: Should work normally")
    print()
    print("📖 See AUTHENTICATION_IMPLEMENTATION_GUIDE.md for detailed instructions")
    print()
    print("=" * 80)

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️  Script interrupted by user")
    except Exception as e:
        print(f"\n\n❌ Unexpected error: {e}")
        import traceback
        traceback.print_exc()
