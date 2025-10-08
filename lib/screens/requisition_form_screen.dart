// lib/screens/requisition_form_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/requisition_provider.dart';
import '../models/requisition/requisition.dart';

class RequisitionFormScreen extends StatefulWidget {
  final Requisition? requisition;

  const RequisitionFormScreen({
    Key? key,
    this.requisition,
  }) : super(key: key);

  @override
  State<RequisitionFormScreen> createState() => _RequisitionFormScreenState();
}

class _RequisitionFormScreenState extends State<RequisitionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Form controllers
  final _jobPositionController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _essentialSkillsController = TextEditingController();
  final _desiredSkillsController = TextEditingController();
  final _jobDescriptionController = TextEditingController();
  final _justificationController = TextEditingController();
  final _preferredAgeController = TextEditingController();
  
  // Form data
  String? _selectedDepartment;
  String? _selectedGender;
  String _jobDescriptionType = 'text';
  File? _selectedFile;
  String? _existingFileUrl;
  
  // Position cards
  List<RequisitionPositionCard> _positionCards = [];
  
  // UI state
  bool _showPositionCards = true;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.requisition != null;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<RequisitionProvider>(context, listen: false);
      provider.initialize().then((_) {
        if (_isEditMode) {
          _loadExistingData();
        } else {
          _addDefaultPositionCard();
        }
      });
    });
  }

  void _loadExistingData() {
    final req = widget.requisition!;
    
    _jobPositionController.text = req.jobPosition;
    _qualificationController.text = req.qualification;
    _experienceController.text = req.experience;
    _essentialSkillsController.text = req.essentialSkills;
    _desiredSkillsController.text = req.desiredSkills ?? '';
    _jobDescriptionController.text = req.jobDescription ?? '';
    _justificationController.text = req.justificationText ?? '';
    _preferredAgeController.text = req.preferredAgeGroup ?? '';
    
    _selectedDepartment = req.department;
    _selectedGender = req.preferredGender;
    _jobDescriptionType = req.jobDescriptionType;
    _existingFileUrl = req.jobDocumentUrl;
    
    // Load position cards
    _positionCards = req.positions.map((pos) => RequisitionPositionCard.fromPosition(pos)).toList();
    
    if (_positionCards.isEmpty) {
      _addDefaultPositionCard();
    }
  }

  void _addDefaultPositionCard() {
    setState(() {
      _positionCards.add(RequisitionPositionCard());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Requisition' : 'Create New Requisition'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
      body: Consumer<RequisitionProvider>(
        builder: (context, provider, child) {
          if (provider.loading && !_isEditMode) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Header
              _buildHeader(),
              
              // Error banner
              if (provider.error != null) _buildErrorBanner(provider),
              
              // Form content
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBasicInformation(provider),
                        const SizedBox(height: 24),
                        _buildJobDescription(),
                        const SizedBox(height: 24),
                        _buildPositionCards(provider),
                        const SizedBox(height: 24),
                        _buildPersonSpecification(provider),
                        const SizedBox(height: 24),
                        _buildSkillsSection(),
                        const SizedBox(height: 24),
                        _buildJustificationSection(),
                        const SizedBox(height: 32),
                        _buildActionButtons(provider),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          // Logo placeholder
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.business, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SRI RAMACHANDRA MEDICAL CENTER',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  'PORUR, CHENNAI-600116',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const Text(
                  'TALENT REQUISITION FORM - NEW POSITION/REPLACEMENT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(RequisitionProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.red[50],
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              provider.error!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => provider.clearError(),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInformation(RequisitionProvider provider) {
    return _buildSection(
      title: 'Basic Information',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedDepartment,
                  decoration: const InputDecoration(
                    labelText: 'Department *',
                    border: OutlineInputBorder(),
                  ),
                  items: provider.departments.map((dept) => DropdownMenuItem(
                    value: dept.id.toString(),
                    child: Text(dept.referenceValue),
                  )).toList(),
                  onChanged: (value) => setState(() => _selectedDepartment = value),
                  validator: (value) => value == null ? 'Department is required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _jobPositionController,
                  decoration: const InputDecoration(
                    labelText: 'Job Position *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Job position is required' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobDescription() {
    return _buildSection(
      title: 'Job Description *',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Job Description Type Toggle
          Row(
            children: [
              Radio<String>(
                value: 'text',
                groupValue: _jobDescriptionType,
                onChanged: (value) => setState(() => _jobDescriptionType = value!),
              ),
              const Text('Text Description'),
              const SizedBox(width: 24),
              Radio<String>(
                value: 'upload',
                groupValue: _jobDescriptionType,
                onChanged: (value) => setState(() => _jobDescriptionType = value!),
              ),
              const Text('Upload Document'),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_jobDescriptionType == 'text') ...[
            TextFormField(
              controller: _jobDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Job Description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 6,
              validator: (value) => value?.isEmpty == true ? 'Job description is required' : null,
            ),
          ] else ...[
            _buildFileUpload(),
          ],
        ],
      ),
    );
  }

  Widget _buildFileUpload() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          if (_selectedFile == null && _existingFileUrl == null) ...[
            Icon(Icons.cloud_upload, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Click to upload job description document'),
            const SizedBox(height: 8),
            Text(
              'PDF, DOC, DOCX, JPG, PNG up to 5MB',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickFile,
              child: const Text('Choose File'),
            ),
          ] else ...[
            _buildFilePreview(),
          ],
        ],
      ),
    );
  }

  Widget _buildFilePreview() {
    final fileName = _selectedFile?.path.split('/').last ?? 
                   _existingFileUrl?.split('/').last ?? 
                   'Unknown file';
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.insert_drive_file, color: Colors.blue[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  _selectedFile != null ? 'New file' : 'Existing file',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          if (_existingFileUrl != null)
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () => _viewFile(_existingFileUrl!),
              tooltip: 'Preview',
            ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => setState(() {
              _selectedFile = null;
              _existingFileUrl = null;
            }),
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }

  Widget _buildPositionCards(RequisitionProvider provider) {
    return _buildSection(
      title: 'Requisition Details',
      child: Column(
        children: [
          Row(
            children: [
              if (_showPositionCards)
                const Text(
                  'Requisition Details Cards',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.green),
                ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => setState(() => _showPositionCards = !_showPositionCards),
                icon: Icon(_showPositionCards ? Icons.expand_less : Icons.expand_more),
                label: Text(_showPositionCards ? 'Hide Details' : 'Add Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          
          if (_showPositionCards) ...[
            const SizedBox(height: 16),
            ..._positionCards.asMap().entries.map((entry) {
              final index = entry.key;
              final card = entry.value;
              return _buildPositionCard(provider, index, card);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildPositionCard(RequisitionProvider provider, int index, RequisitionPositionCard card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border.all(color: Colors.green[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header with actions
          Row(
            children: [
              Text(
                'Requisition Details Card #${index + 1}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green),
                onPressed: () => setState(() => _positionCards.add(RequisitionPositionCard())),
                tooltip: 'Add new card',
              ),
              if (_positionCards.length > 1)
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () => setState(() => _positionCards.removeAt(index)),
                  tooltip: 'Remove this card',
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Position card fields
          _buildPositionCardFields(provider, card),
        ],
      ),
    );
  }

  Widget _buildPositionCardFields(RequisitionProvider provider, RequisitionPositionCard card) {
    return Column(
      children: [
        // Basic fields row
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: card.typeRequisition,
                decoration: const InputDecoration(
                  labelText: 'Type of Requisition *',
                  border: OutlineInputBorder(),
                ),
                items: provider.requisitionTypes.map((type) => DropdownMenuItem(
                  value: type.id.toString(),
                  child: Text(type.referenceValue),
                )).toList(),
                onChanged: (value) => setState(() {
                  card.typeRequisition = value ?? '1';
                  if (value == '2') { // Replacement
                    card.headcount = '1';
                  }
                }),
              ),
            ),
            const SizedBox(width: 12),
            
            Expanded(
              child: DropdownButtonFormField<String>(
                value: card.requirementsReason,
                decoration: const InputDecoration(
                  labelText: 'Reason for Requisition *',
                  border: OutlineInputBorder(),
                ),
                items: (card.typeRequisition == '1' ? provider.newHireReasons : provider.replacementReasons)
                    .map((reason) => DropdownMenuItem(
                      value: reason.id.toString(),
                      child: Text(reason.referenceValue),
                    )).toList(),
                onChanged: (value) => setState(() => card.requirementsReason = value),
              ),
            ),
            const SizedBox(width: 12),
            
            Expanded(
              child: TextFormField(
                initialValue: card.headcount,
                decoration: InputDecoration(
                  labelText: 'Head Count *',
                  border: const OutlineInputBorder(),
                  enabled: card.typeRequisition != '2', // Disabled for replacement
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => card.headcount = value,
                validator: (value) {
                  if (value?.isEmpty == true) return 'Head count is required';
                  final count = int.tryParse(value!);
                  if (count == null || count <= 0) return 'Must be a positive number';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            
            Expanded(
              child: TextFormField(
                initialValue: card.vacancyToBeFilled,
                decoration: const InputDecoration(
                  labelText: 'Vacancy to be Filled On *',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      card.vacancyToBeFilled = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            
            Expanded(
              child: DropdownButtonFormField<String>(
                value: card.employmentType,
                decoration: const InputDecoration(
                  labelText: 'Employment Type *',
                  border: OutlineInputBorder(),
                ),
                items: provider.employmentTypes.map((type) => DropdownMenuItem(
                  value: type.id.toString(),
                  child: Text(type.referenceValue),
                )).toList(),
                onChanged: (value) => setState(() => card.employmentType = value),
              ),
            ),
          ],
        ),
        
        // Employee information for replacement
        if (card.typeRequisition == '2') ...[
          const SizedBox(height: 16),
          const Text(
            'Employee Information',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: card.employeeNo,
                  decoration: const InputDecoration(
                    labelText: 'Employee No *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => card.employeeNo = value,
                  validator: (value) => card.typeRequisition == '2' && value?.isEmpty == true 
                      ? 'Employee number is required for replacement' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: card.employeeName,
                  decoration: const InputDecoration(
                    labelText: 'Employee Name *',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => card.employeeName = value,
                  validator: (value) => card.typeRequisition == '2' && value?.isEmpty == true 
                      ? 'Employee name is required for replacement' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: card.dateOfResignation,
                  decoration: const InputDecoration(
                    labelText: 'Date of Resignation *',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        card.dateOfResignation = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                      });
                    }
                  },
                  validator: (value) => card.typeRequisition == '2' && value?.isEmpty == true 
                      ? 'Date of resignation is required for replacement' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: card.resignationReason,
                  decoration: const InputDecoration(
                    labelText: 'Resignation Reason *',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => card.resignationReason = value,
                  validator: (value) => card.typeRequisition == '2' && value?.isEmpty == true 
                      ? 'Resignation reason is required for replacement' : null,
                ),
              ),
            ],
          ),
        ],
        
        const SizedBox(height: 16),
        TextFormField(
          initialValue: card.justificationText,
          decoration: const InputDecoration(
            labelText: 'Justification Text *',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
          onChanged: (value) => card.justificationText = value,
          validator: (value) => value?.isEmpty == true ? 'Justification text is required' : null,
        ),
      ],
    );
  }

  Widget _buildPersonSpecification(RequisitionProvider provider) {
    return _buildSection(
      title: 'Person Specification & Justification',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Preferred Gender',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Select Gender')),
                    ...provider.genders.map((gender) => DropdownMenuItem(
                      value: gender.id.toString(),
                      child: Text(gender.referenceValue),
                    )),
                  ],
                  onChanged: (value) => setState(() => _selectedGender = value),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _preferredAgeController,
                  decoration: const InputDecoration(
                    labelText: 'Preferred Age Group',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _qualificationController,
                  decoration: const InputDecoration(
                    labelText: 'Qualification *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Qualification is required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _experienceController,
                  decoration: const InputDecoration(
                    labelText: 'Experience Required (in years) *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Experience is required' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection() {
    return _buildSection(
      title: 'Skills',
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 120,
                child: Text(
                  'Essential Skills *',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _essentialSkillsController,
                      decoration: const InputDecoration(
                        hintText: 'Enter essential skills separated by commas (e.g., JavaScript, React, Node.js)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value?.isEmpty == true ? 'Essential skills are required' : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Separate multiple skills with commas (,)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 120,
                child: Text(
                  'Desirable Skills',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _desiredSkillsController,
                      decoration: const InputDecoration(
                        hintText: 'Enter desirable skills separated by commas (e.g., Python, SQL, Docker)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Separate multiple skills with commas (,)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJustificationSection() {
    return _buildSection(
      title: 'Justification Text',
      child: TextFormField(
        controller: _justificationController,
        decoration: const InputDecoration(
          labelText: 'Justification Text',
          border: OutlineInputBorder(),
          alignLabelWithHint: true,
        ),
        maxLines: 4,
      ),
    );
  }

  Widget _buildActionButtons(RequisitionProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: provider.saving ? null : () => _submitForm(provider),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: provider.saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditMode ? 'Update Requisition' : 'Save Requisition'),
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // Helper methods
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = File(result.files.first.path!);
      final fileSize = await file.length();
      
      if (fileSize > 5 * 1024 * 1024) { // 5MB limit
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File size must be less than 5MB'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _selectedFile = file;
        _existingFileUrl = null; // Clear existing file when new file is selected
      });
    }
  }

  void _viewFile(String url) {
    // TODO: Implement file viewing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening: $url')),
    );
  }

  Future<void> _submitForm(RequisitionProvider provider) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the validation errors'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate job description
    if (_jobDescriptionType == 'text' && _jobDescriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job description is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_jobDescriptionType == 'upload' && _selectedFile == null && _existingFileUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a job description document'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create requisition object
    final positions = _positionCards.map((card) => card.toRequisitionPosition()).toList();
    final skills = <RequisitionSkill>[];
    
    // Parse essential skills
    final essentialSkills = _essentialSkillsController.text
        .split(',')
        .map((skill) => skill.trim())
        .where((skill) => skill.isNotEmpty);
    for (final skill in essentialSkills) {
      skills.add(RequisitionSkill(skill: skill, skillType: 'essential'));
    }
    
    // Parse desired skills
    final desiredSkills = _desiredSkillsController.text
        .split(',')
        .map((skill) => skill.trim())
        .where((skill) => skill.isNotEmpty);
    for (final skill in desiredSkills) {
      skills.add(RequisitionSkill(skill: skill, skillType: 'desired'));
    }

    final requisition = Requisition(
      id: widget.requisition?.id,
      jobPosition: _jobPositionController.text.trim(),
      department: _selectedDepartment!,
      jobDescription: _jobDescriptionType == 'text' ? _jobDescriptionController.text.trim() : null,
      jobDescriptionType: _jobDescriptionType,
      preferredGender: _selectedGender,
      preferredAgeGroup: _preferredAgeController.text.trim().isNotEmpty 
          ? _preferredAgeController.text.trim() : null,
      qualification: _qualificationController.text.trim(),
      experience: _experienceController.text.trim(),
      justificationText: _justificationController.text.trim().isNotEmpty 
          ? _justificationController.text.trim() : null,
      essentialSkills: _essentialSkillsController.text.trim(),
      desiredSkills: _desiredSkillsController.text.trim().isNotEmpty 
          ? _desiredSkillsController.text.trim() : null,
      positions: positions,
      skills: skills,
    );

    bool success;
    if (_isEditMode) {
      success = await provider.updateRequisition(
        widget.requisition!.id!,
        requisition,
        jobDocument: _selectedFile,
      );
    } else {
      success = await provider.createRequisition(
        requisition,
        jobDocument: _selectedFile,
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode 
                ? 'Requisition updated successfully!' 
                : 'Requisition created successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _jobPositionController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    _essentialSkillsController.dispose();
    _desiredSkillsController.dispose();
    _jobDescriptionController.dispose();
    _justificationController.dispose();
    _preferredAgeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// Helper class for managing position cards
class RequisitionPositionCard {
  String typeRequisition;
  String? requirementsReason;
  String headcount;
  String? vacancyToBeFilled;
  String? employmentType;
  String? justificationText;
  String? employeeName;
  String? employeeNo;
  String? dateOfResignation;
  String? resignationReason;

  RequisitionPositionCard({
    this.typeRequisition = '1',
    this.requirementsReason,
    this.headcount = '1',
    this.vacancyToBeFilled,
    this.employmentType,
    this.justificationText,
    this.employeeName,
    this.employeeNo,
    this.dateOfResignation,
    this.resignationReason,
  }) {
    // Set default vacancy date to 30 days from now
    vacancyToBeFilled ??= DateTime.now()
        .add(const Duration(days: 30))
        .toIso8601String()
        .split('T')[0];
  }

  factory RequisitionPositionCard.fromPosition(RequisitionPosition position) {
    return RequisitionPositionCard(
      typeRequisition: position.typeRequisition,
      requirementsReason: position.typeRequisition == '1' 
          ? position.requirementsRequisitionNewhire 
          : position.requirementsRequisitionReplacement,
      headcount: position.requisitionQuantity.toString(),
      vacancyToBeFilled: position.vacancyToBeFilled,
      employmentType: position.employmentType,
      justificationText: position.justificationText,
      employeeName: position.employeeName,
      employeeNo: position.employeeNo,
      dateOfResignation: position.dateOfResignation,
      resignationReason: position.resignationReason,
    );
  }

  RequisitionPosition toRequisitionPosition() {
    return RequisitionPosition(
      typeRequisition: typeRequisition,
      requirementsRequisitionNewhire: typeRequisition == '1' ? requirementsReason : null,
      requirementsRequisitionReplacement: typeRequisition == '2' ? requirementsReason : null,
      requisitionQuantity: int.tryParse(headcount) ?? 1,
      vacancyToBeFilled: vacancyToBeFilled,
      employmentType: employmentType,
      justificationText: justificationText,
      employeeName: employeeName,
      employeeNo: employeeNo,
      dateOfResignation: dateOfResignation,
      resignationReason: resignationReason,
    );
  }
}
