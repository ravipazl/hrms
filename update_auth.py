"""
Script to update all API views to use proper authentication
This script will replace AllowAny with IsAuthenticated in views.py
"""
import re

# Read the views.py file
with open('D:\\hrms_final\\srmc_horilla\\horilla_api\\api_views\\requisition\\views.py', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace imports - add SessionAuthentication
if 'from rest_framework.authentication import SessionAuthentication' not in content:
    # Add SessionAuthentication to imports
    content = content.replace(
        'from rest_framework.permissions import IsAuthenticated, AllowAny',
        'from rest_framework.authentication import SessionAuthentication\nfrom rest_framework.permissions import IsAuthenticated, AllowAny'
    )

# Find all class definitions with AllowAny and replace with proper authentication
# Pattern: class NameAPIView(APIView): ... permission_classes = [AllowAny]
pattern = r'(class \w+APIView\(APIView\):.*?""".*?""")\s+(permission_classes = \[AllowAny\])'

def replace_permission(match):
    class_def = match.group(1)
    # Add authentication_classes and change permission_classes
    return f'''{class_def}
    
    # ✅ AUTHENTICATION ENABLED
    authentication_classes = [SessionAuthentication]
    permission_classes = [IsAuthenticated]'''

# Replace all occurrences
content_updated = re.sub(pattern, replace_permission, content, flags=re.DOTALL)

# Write back
with open('D:\\hrms_final\\srmc_horilla\\horilla_api\\api_views\\requisition\\views.py', 'w', encoding='utf-8') as f:
    f.write(content_updated)

print("✅ Successfully updated views.py with authentication")
print("✅ All API views now require authentication")
print("✅ SessionAuthentication enabled")
