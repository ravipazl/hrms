// lib/screens/requisition_form_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hrms/models/requisition.dart';
import 'dart:html' as html;
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/requisition_provider.dart';
import '../widgets/enhanced_file_upload_widget.dart';

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
  
  // Date field controllers for position cards
  final Map<int, TextEditingController> _vacancyDateControllers = {};
  final Map<int, TextEditingController> _resignationDateControllers = {};
  
  // Form data
  String? _selectedDepartment;
  String? _selectedGender;
  String _jobDescriptionType = 'text';
  File? _selectedFile;
  PlatformFile? _selectedPlatformFile; // For web compatibility
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
    
   
    if (widget.requisition != null) {
     
    }
    
    // Load data immediately if in edit mode
    if (_isEditMode && widget.requisition != null) {
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingData();
      });
    } else {
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _addDefaultPositionCard();
      });
    }
    
    // Initialize provider separately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<RequisitionProvider>(context, listen: false);
      if (provider.departments.isEmpty) {
        provider.initialize();
      }
    });
  }

  void _loadExistingData() {
    if (widget.requisition == null) {
      print('❌ No requisition data to load');
      return;
    }
    
    final req = widget.requisition!;
    print('📋 Loading existing requisition data for edit mode:');
    print('   - ID: ${req.id}');
    print('   - Job Position: ${req.jobPosition}');
    print('   - Job Description Type: ${req.jobDescriptionType}');
    print('   - Job Document URL: ${req.jobDocumentUrl}');
    print('   - Job Document: ${req.jobDocument}');
    
    setState(() {
      // Set basic fields
      _jobPositionController.text = req.jobPosition ?? '';
      _qualificationController.text = req.qualification ?? '';
      _experienceController.text = req.experience ?? '';
      _essentialSkillsController.text = req.essentialSkills ?? '';
      _desiredSkillsController.text = req.desiredSkills ?? '';
      _jobDescriptionController.text = req.jobDescription ?? '';
      _justificationController.text = req.justificationText ?? '';
      _preferredAgeController.text = req.preferredAgeGroup ?? '';
      
      // Set dropdown values
      _selectedDepartment = req.department;
      _selectedGender = req.preferredGender;
      
      // FIXED: Properly handle job description type and existing file
      // Priority: jobDocumentUrl > jobDocument > text mode
      if (req.jobDocumentUrl != null && req.jobDocumentUrl!.isNotEmpty) {
        _jobDescriptionType = 'upload';
        _existingFileUrl = req.jobDocumentUrl;
        print('✅ Found existing document URL: $_existingFileUrl');
      } else if (req.jobDocument != null && req.jobDocument!.isNotEmpty) {
        _jobDescriptionType = 'upload';
        _existingFileUrl = req.jobDocument;
        print('✅ Found existing document path: $_existingFileUrl');
      } else {
        // Use the stored job description type, defaulting to 'text'
        _jobDescriptionType = req.jobDescriptionType ?? 'text';
        _existingFileUrl = null;
        print('📝 Using text description mode');
      }
      
      // ENHANCED: Debug existing file information
      if (_existingFileUrl != null) {
        print('🔗 Existing file URL ready for preview: $_existingFileUrl');
        print('🎯 Job description type set to: $_jobDescriptionType');
      }
      
      // Load position cards
      if (req.positions.isNotEmpty) {
        _positionCards = req.positions.map((pos) => RequisitionPositionCard.fromPosition(pos)).toList();
        print('✅ Loaded ${_positionCards.length} position cards');
      } else {
        _addDefaultPositionCard();
        print('➕ Added default position card');
      }
    });
    
    print('✅ Existing data loaded successfully in edit mode');
  }

  void _addDefaultPositionCard() {
    setState(() {
      _positionCards.add(RequisitionPositionCard());
    });
  }

  // Navigation helper method
  void _navigateToRequisitionList() {
    
    html.window.location.href = 'http://127.0.0.1:8000/requisition/';
  }

  Widget _buildLogo() {
    // Try to load image logo first, fallback to triangle if not found
    return FutureBuilder<bool>(
      future: _checkIfImageExists(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == true) {
          // Show image logo
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              _getLogoPath(),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to triangle if image fails to load
                return CustomPaint(
                  painter: TrianglePainter(),
                );
              },
            ),
          );
        } else {
          // Show triangle logo as fallback
          return CustomPaint(
            painter: TrianglePainter(),
          );
        }
      },
    );
  }

  Future<bool> _checkIfImageExists() async {
    try {
      final logoPath = _getLogoPath();
      await rootBundle.load(logoPath);
      return true;
    } catch (e) {
      return false;
    }
  }

  String _getLogoPath() {
    // Return the primary logo path
    return 'assets/images/logo.png';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Requisition' : 'Create New Requisition'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _navigateToRequisitionList,
          tooltip: 'Back to Requisition List',
        ),
        // actions: [
        //   if (_isEditMode)
        //     Container(
        //       margin: const EdgeInsets.all(8),
        //       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        //       decoration: BoxDecoration(
        //         color: Colors.blue[50],
        //         borderRadius: BorderRadius.circular(16),
        //         border: Border.all(color: Colors.blue[200]!),
        //       ),
        //       child: Text(
        //         'ID: ${widget.requisition?.id ?? 'N/A'}',
        //         style: TextStyle(
        //           color: Colors.blue[700],
        //           fontWeight: FontWeight.w500,
        //         ),
        //       ),
        //     ),
        //   TextButton(
        //     onPressed: _navigateToRequisitionList,
        //     child: const Text('Cancel'),
        //   ),
        // ],
      ),
      body: Consumer<RequisitionProvider>(
        builder: (context, provider, child) {
          if (provider.loading && _positionCards.isEmpty && !_isEditMode) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header (now scrollable)
                  _buildHeader(),
                  
                  // Edit mode indicator
                  if (_isEditMode) _buildEditModeIndicator(),
                  
                  // Error banner
                  if (provider.error != null) _buildErrorBanner(provider),
                  
                  const SizedBox(height: 24),
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
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo and company name
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Company logo
              Container(
                width: 40,
                height: 35,
                child: _buildLogo(),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'SRI RAMACHANDRA MEDICAL CENTER',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width < 600 ? 18 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Location
          Text(
            'PORUR,CHENNAI-600116',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 16,
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Form title
          Text(
            'TALENT REQUISITION FORM - NEW POSITION/REPLACEMENT',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width < 600 ? 12 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEditModeIndicator() {
    return Container(
      // width: double.infinity,
      // padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      // color: Colors.blue[50],
      // child: Column(
      //   children: [
      //     const Text(
      //       'Edit Requisition',
      //       style: TextStyle(
      //         fontSize: 20,
      //         fontWeight: FontWeight.bold,
      //         color: Colors.blue,
      //       ),
      //     ),
      //     const SizedBox(height: 4),
      //     Text(
      //       'Fill in the details below to update a requisition request',
      //       style: TextStyle(
      //         fontSize: 14,
      //         color: Colors.blue[700],
      //       ),
      //     ),
      //   ],
      // ),
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
    // FIXED: Add unique key to force widget rebuild when existing file URL changes
    final widgetKey = Key('file-upload-${_existingFileUrl ?? 'new'}-${_selectedFile?.path ?? 'none'}-${_selectedPlatformFile?.name ?? 'none'}');
    
    return EnhancedFileUploadWidget(
      key: widgetKey,
      label: null, // We handle the label in the parent section
      helpText: 'Upload job description document (PDF, DOC, DOCX, JPG, PNG up to 5MB)',
      required: _jobDescriptionType == 'upload',
      initialFile: _selectedFile,
      initialFileUrl: _existingFileUrl,
      onFileChanged: (File? file) {
        setState(() {
          _selectedFile = file;
          if (file != null) {
            _existingFileUrl = null; // Clear existing file when new file is selected
            print('🔄 New file selected, cleared existing URL');
          }
        });
      },
      onPlatformFileChanged: (PlatformFile? platformFile) {
        setState(() {
          _selectedPlatformFile = platformFile;
          if (platformFile != null) {
            _existingFileUrl = null; // Clear existing file when new file is selected
            print('🔄 New platform file selected, cleared existing URL');
          }
        });
      },
      onError: (String? error) {
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      allowedExtensions: const ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      maxFileSizeInMB: 5,
      showPreview: true,
      enabled: true,
    );
  }

  // File preview is now handled by the EnhancedFileUploadWidget

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
        // Basic fields row - First Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: DropdownButtonFormField<String>(
                  value: card.typeRequisition,
                  decoration: const InputDecoration(
                    labelText: 'Type of Requisition *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
            ),
            
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: DropdownButtonFormField<String>(
                  value: card.requirementsReason,
                  decoration: const InputDecoration(
                    labelText: 'Reason for Requisition *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  items: (card.typeRequisition == '1' ? provider.newHireReasons : provider.replacementReasons)
                      .map((reason) => DropdownMenuItem(
                        value: reason.id.toString(),
                        child: Text(
                          reason.referenceValue,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )).toList(),
                  onChanged: (value) => setState(() => card.requirementsReason = value),
                  isExpanded: true,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Second Row - Head Count, Vacancy Date, Employment Type
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: TextFormField(
                  initialValue: card.headcount,
                  decoration: InputDecoration(
                    labelText: 'Head Count *',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
            ),
            
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: TextFormField(
                  initialValue: card.vacancyToBeFilled,
                  decoration: const InputDecoration(
                    labelText: 'Vacancy to be Filled On *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
            ),
            
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: DropdownButtonFormField<String>(
                  value: card.employmentType,
                  decoration: const InputDecoration(
                    labelText: 'Employment Type *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  items: provider.employmentTypes.map((type) => DropdownMenuItem(
                    value: type.id.toString(),
                    child: Text(type.referenceValue),
                  )).toList(),
                  onChanged: (value) => setState(() => card.employmentType = value),
                  isExpanded: true,
                ),
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
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left side - Preview button
        ElevatedButton.icon(
          onPressed: () => _showFormPreview(),
          icon: const Icon(Icons.preview),
          label: const Text('Preview Form'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        
        // Right side - Cancel and Save buttons
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              onPressed: _navigateToRequisitionList,
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

  // File handling is now managed by the EnhancedFileUploadWidget

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

    if (_jobDescriptionType == 'upload' && 
        _selectedFile == null && 
        _selectedPlatformFile == null && 
        _existingFileUrl == null) {
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
      // Determine which file to use
      File? fileToUpload;
      PlatformFile? platformFileToUpload;
      
      if (kIsWeb) {
        platformFileToUpload = _selectedPlatformFile;
      } else {
        fileToUpload = _selectedFile;
      }
      
      success = await provider.updateRequisition(
        widget.requisition!.id!,
        requisition,
        jobDocument: fileToUpload,

      );
    } else {
      // Determine which file to use
      File? fileToUpload;
      PlatformFile? platformFileToUpload;
      
      if (kIsWeb) {
        platformFileToUpload = _selectedPlatformFile;
      } else {
        fileToUpload = _selectedFile;
      }
      
      success = await provider.createRequisition(
        requisition,
        jobDocument: fileToUpload,

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
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Wait for snackbar to show, then redirect to Django requisition list
      Future.delayed(const Duration(seconds: 2), () {
        print('✅ Operation successful, redirecting to Django requisition list');
        _navigateToRequisitionList();
      });
    }
  }

  /// Show form preview dialog
  void _showFormPreview() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.95,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                // Preview Header
                _buildPreviewHeader(),
                
                // Preview Content (Scrollable)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildPreviewContent(),
                  ),
                ),
                
                // Preview Footer
                _buildPreviewFooter(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build preview header
  Widget _buildPreviewHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.preview,
            color: Colors.blue[600],
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Requisition Form Preview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                Text(
                  _isEditMode ? 'Edit Mode - ID: ${widget.requisition?.id ?? 'N/A'}' : 'New Requisition',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: 'Close Preview',
          ),
        ],
      ),
    );
  }

  /// Build preview content (read-only form view)
  Widget _buildPreviewContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        _buildPreviewSection(
          title: 'Company Information',
          child: _buildPreviewCompanyHeader(),
        ),
        
        const SizedBox(height: 16),
        
        // Basic Information
        _buildPreviewSection(
          title: 'Basic Information',
          child: _buildPreviewBasicInfo(),
        ),
        
        const SizedBox(height: 16),
        
        // Job Description
        _buildPreviewSection(
          title: 'Job Description',
          child: _buildPreviewJobDescription(),
        ),
        
        const SizedBox(height: 16),
        
        // Position Details
        if (_positionCards.isNotEmpty)
          _buildPreviewSection(
            title: 'Position Details',
            child: _buildPreviewPositionDetails(),
          ),
        
        const SizedBox(height: 16),
        
        // Person Specification
        _buildPreviewSection(
          title: 'Person Specification',
          child: _buildPreviewPersonSpecification(),
        ),
        
        const SizedBox(height: 16),
        
        // Skills
        _buildPreviewSection(
          title: 'Skills Requirements',
          child: _buildPreviewSkills(),
        ),
        
        const SizedBox(height: 16),
        
        // Justification
        if (_justificationController.text.isNotEmpty)
          _buildPreviewSection(
            title: 'Justification',
            child: _buildPreviewJustification(),
          ),
      ],
    );
  }

  /// Build preview section wrapper
  Widget _buildPreviewSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  /// Build company header preview
  Widget _buildPreviewCompanyHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 35,
              child: _buildLogo(),
            ),
            const SizedBox(width: 12),
            const Text(
              'SRI RAMACHANDRA MEDICAL CENTER',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'PORUR,CHENNAI-600116',
          style: TextStyle(
            fontSize: 14,
            color: Colors.blue,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'TALENT REQUISITION FORM - NEW POSITION/REPLACEMENT',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build basic info preview
  Widget _buildPreviewBasicInfo() {
    return Column(
      children: [
        _buildPreviewRow('Department', _getDisplayValue(_selectedDepartment, 'departments')),
        _buildPreviewRow('Job Position', _jobPositionController.text),
      ],
    );
  }

  /// Build job description preview
  Widget _buildPreviewJobDescription() {
    if (_jobDescriptionType == 'text') {
      return _buildPreviewRow('Job Description', _jobDescriptionController.text, isMultiline: true);
    } else {
      String fileInfo = 'No document uploaded';
      if (_selectedFile != null) {
        fileInfo = 'File: ${_selectedFile!.path.split('/').last}';
      } else if (_selectedPlatformFile != null) {
        fileInfo = 'File: ${_selectedPlatformFile!.name} (${_formatFileSize(_selectedPlatformFile!.size)})';
      } else if (_existingFileUrl != null) {
        fileInfo = 'Existing file: ${_existingFileUrl!.split('/').last}';
      }
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPreviewRow('Job Description Type', 'Document Upload'),
          _buildPreviewRow('Document', fileInfo),
          if (_existingFileUrl != null || _selectedPlatformFile != null || _selectedFile != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_existingFileUrl != null) {
                    // Show preview for existing file
                    _previewExistingFile();
                  } else {
                    // Show preview for new file
                    _previewNewFile();
                  }
                },
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('Preview Document'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ),
        ],
      );
    }
  }

  /// Build position details preview
  Widget _buildPreviewPositionDetails() {
    return Column(
      children: _positionCards.asMap().entries.map((entry) {
        final index = entry.key;
        final card = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Position Card #${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              _buildPreviewRow('Type of Requisition', _getDisplayValue(card.typeRequisition, 'requisitionTypes')),
              _buildPreviewRow('Reason', _getDisplayValue(card.requirementsReason, card.typeRequisition == '1' ? 'newHireReasons' : 'replacementReasons')),
              _buildPreviewRow('Head Count', card.headcount),
              _buildPreviewRow('Vacancy Date', card.vacancyToBeFilled ?? 'Not set'),
              _buildPreviewRow('Employment Type', _getDisplayValue(card.employmentType, 'employmentTypes')),
              if (card.typeRequisition == '2') ...[
                const SizedBox(height: 8),
                const Text(
                  'Employee Information:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                _buildPreviewRow('Employee No', card.employeeNo ?? ''),
                _buildPreviewRow('Employee Name', card.employeeName ?? ''),
                _buildPreviewRow('Date of Resignation', card.dateOfResignation ?? ''),
                _buildPreviewRow('Resignation Reason', card.resignationReason ?? ''),
              ],
              if (card.justificationText?.isNotEmpty == true)
                _buildPreviewRow('Justification', card.justificationText!, isMultiline: true),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Build person specification preview
  Widget _buildPreviewPersonSpecification() {
    return Column(
      children: [
        _buildPreviewRow('Preferred Gender', _getDisplayValue(_selectedGender, 'genders')),
        _buildPreviewRow('Preferred Age Group', _preferredAgeController.text),
        _buildPreviewRow('Qualification', _qualificationController.text),
        _buildPreviewRow('Experience Required', _experienceController.text),
      ],
    );
  }

  /// Build skills preview
  Widget _buildPreviewSkills() {
    return Column(
      children: [
        _buildPreviewRow('Essential Skills', _essentialSkillsController.text, isMultiline: true),
        _buildPreviewRow('Desirable Skills', _desiredSkillsController.text, isMultiline: true),
      ],
    );
  }

  /// Build justification preview
  Widget _buildPreviewJustification() {
    return _buildPreviewRow('Justification Text', _justificationController.text, isMultiline: true);
  }

  /// Build preview row
  Widget _buildPreviewRow(String label, String value, {bool isMultiline = false}) {
    if (value.isEmpty) {
      value = 'Not specified';
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: value == 'Not specified' ? Colors.grey : Colors.black,
                fontStyle: value == 'Not specified' ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get display value for dropdowns
  String _getDisplayValue(String? value, String type) {
    if (value == null || value.isEmpty) return 'Not selected';
    
    final provider = Provider.of<RequisitionProvider>(context, listen: false);
    
    switch (type) {
      case 'departments':
        final item = provider.departments.firstWhere((dept) => dept.id.toString() == value, orElse: () => ReferenceData(id: 0, referenceValue: 'Unknown'));
        return item.referenceValue;
      case 'genders':
        final item = provider.genders.firstWhere((gender) => gender.id.toString() == value, orElse: () => ReferenceData(id: 0, referenceValue: 'Unknown'));
        return item.referenceValue;
      case 'requisitionTypes':
        final item = provider.requisitionTypes.firstWhere((type) => type.id.toString() == value, orElse: () => ReferenceData(id: 0, referenceValue: 'Unknown'));
        return item.referenceValue;
      case 'newHireReasons':
        final item = provider.newHireReasons.firstWhere((reason) => reason.id.toString() == value, orElse: () => ReferenceData(id: 0, referenceValue: 'Unknown'));
        return item.referenceValue;
      case 'replacementReasons':
        final item = provider.replacementReasons.firstWhere((reason) => reason.id.toString() == value, orElse: () => ReferenceData(id: 0, referenceValue: 'Unknown'));
        return item.referenceValue;
      case 'employmentTypes':
        final item = provider.employmentTypes.firstWhere((type) => type.id.toString() == value, orElse: () => ReferenceData(id: 0, referenceValue: 'Unknown'));
        return item.referenceValue;
      default:
        return value;
    }
  }

  /// Preview existing file from form preview - Direct opening
  void _previewExistingFile() {
    if (_existingFileUrl != null) {
      print('🔗 Opening existing file directly: $_existingFileUrl');
      
      if (kIsWeb) {
        // Determine file extension for optimized viewing
        final fileName = _existingFileUrl!.split('/').last;
        final extension = _getFileExtension(fileName).toLowerCase();
        
        String viewUrl = _existingFileUrl!;
        if (extension == 'pdf') {
          viewUrl = '$_existingFileUrl#view=FitH';
        } else if (['doc', 'docx'].contains(extension)) {
          if (_existingFileUrl!.contains('127.0.0.1') || _existingFileUrl!.contains('localhost')) {
            viewUrl = _existingFileUrl!.contains('?') ? '$_existingFileUrl&disposition=inline' : '$_existingFileUrl?disposition=inline';
          }
        }
        
        html.window.open(viewUrl, '_blank');
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening ${fileName} in new tab...'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green[600],
          ),
        );
      } else {
        launchUrl(Uri.parse(_existingFileUrl!), mode: LaunchMode.externalApplication);
      }
    }
  }

  /// Preview new file from form preview - Direct opening
  void _previewNewFile() {
    if (kIsWeb && _selectedPlatformFile != null) {
      // Create blob URL and open directly
      final extension = _getFileExtension(_selectedPlatformFile!.name).toLowerCase();
      final fileName = _selectedPlatformFile!.name;
      
      try {
        if (['pdf', 'jpg', 'jpeg', 'png'].contains(extension)) {
          final mimeType = extension == 'pdf' ? 'application/pdf' : 'image/${extension == 'jpg' ? 'jpeg' : extension}';
          final blob = html.Blob([_selectedPlatformFile!.bytes!], mimeType);
          final url = html.Url.createObjectUrlFromBlob(blob);
          
          // Add PDF viewer parameters if needed
          final viewUrl = extension == 'pdf' ? '$url#view=FitH' : url;
          
          html.window.open(viewUrl, '_blank');
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening $fileName in new tab...'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green[600],
            ),
          );
          
          Future.delayed(const Duration(seconds: 60), () => html.Url.revokeObjectUrl(url));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error previewing file: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  /// Helper method to get file extension
  String _getFileExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot != -1 && lastDot < fileName.length - 1) {
      return fileName.substring(lastDot + 1);
    }
    return '';
  }

  /// Helper method to format file size
  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return "${size.toStringAsFixed(size < 10 ? 1 : 0)} ${suffixes[i]}";
  }

  /// Build preview footer
  Widget _buildPreviewFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Preview Mode - Form data is read-only',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Could add print functionality here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Print functionality can be added here'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.print, size: 16),
                label: const Text('Print'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
    
    // Dispose date controllers
    _vacancyDateControllers.values.forEach((controller) => controller.dispose());
    _resignationDateControllers.values.forEach((controller) => controller.dispose());
    
    super.dispose();
  }
}

// Custom Triangle Painter for the logo fallback
class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0); // Top point
    path.lineTo(0, size.height); // Bottom left
    path.lineTo(size.width, size.height); // Bottom right
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
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
