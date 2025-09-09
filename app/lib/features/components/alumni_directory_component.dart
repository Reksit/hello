import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../common/providers/toast_provider.dart';
import '../common/widgets/glass_card.dart';
import '../common/widgets/gradient_button.dart';
import '../common/widgets/loading_widget.dart';
import '../common/widgets/professional_input.dart';
import '../services/alumni_service.dart';
import '../services/connection_service.dart';

class AlumniDirectoryComponent extends ConsumerStatefulWidget {
  final bool showConnectButton;
  
  const AlumniDirectoryComponent({
    super.key,
    this.showConnectButton = true,
  });

  @override
  ConsumerState<AlumniDirectoryComponent> createState() => _AlumniDirectoryComponentState();
}

class _AlumniDirectoryComponentState extends ConsumerState<AlumniDirectoryComponent> {
  final AlumniService _alumniService = AlumniService();
  final ConnectionService _connectionService = ConnectionService();
  
  List<dynamic> _alumni = [];
  List<dynamic> _filteredAlumni = [];
  bool _loading = true;
  String _searchTerm = '';
  String _selectedDepartment = '';
  String _selectedYear = '';
  Map<String, dynamic>? _selectedAlumni;
  bool _showDetailModal = false;

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAlumniDirectory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAlumniDirectory() async {
    try {
      List<dynamic> response;
      if (widget.showConnectButton) {
        response = await _alumniService.getAllVerifiedAlumni();
      } else {
        response = await _alumniService.getAllVerifiedAlumniForAlumni();
      }
      
      setState(() {
        _alumni = response;
        _filteredAlumni = response;
        _loading = false;
      });
    } catch (error) {
      setState(() => _loading = false);
      if (!error.toString().contains('404')) {
        ref.read(toastProvider.notifier).showToast(
          error.toString().replaceFirst('Exception: ', ''),
          ToastType.error,
        );
      }
    }
  }

  void _filterAlumni() {
    setState(() {
      _filteredAlumni = _alumni.where((alum) {
        final matchesSearch = _searchTerm.isEmpty ||
            alum['name'].toString().toLowerCase().contains(_searchTerm.toLowerCase()) ||
            alum['email'].toString().toLowerCase().contains(_searchTerm.toLowerCase()) ||
            (alum['department']?.toString().toLowerCase().contains(_searchTerm.toLowerCase()) ?? false) ||
            (alum['currentCompany']?.toString().toLowerCase().contains(_searchTerm.toLowerCase()) ?? false);
        
        final matchesDepartment = _selectedDepartment.isEmpty ||
            alum['department'] == _selectedDepartment;
        
        final matchesYear = _selectedYear.isEmpty ||
            alum['graduationYear'].toString() == _selectedYear;
        
        return matchesSearch && matchesDepartment && matchesYear;
      }).toList();
    });
  }

  void _onSearchChanged(String value) {
    setState(() => _searchTerm = value);
    _filterAlumni();
  }

  List<String> _getDepartments() {
    final departments = _alumni
        .map((alum) => alum['department']?.toString())
        .where((dept) => dept != null && dept.isNotEmpty)
        .toSet()
        .toList();
    departments.sort();
    return departments;
  }

  List<String> _getGraduationYears() {
    final years = _alumni
        .map((alum) => alum['graduationYear']?.toString())
        .where((year) => year != null && year.isNotEmpty)
        .toSet()
        .toList();
    years.sort((a, b) => b.compareTo(a));
    return years;
  }

  void _showAlumniDetails(Map<String, dynamic> alumni) {
    setState(() {
      _selectedAlumni = alumni;
      _showDetailModal = true;
    });
  }

  Future<void> _sendConnectionRequest(String alumniId, String alumniName) async {
    try {
      await _connectionService.sendConnectionRequest(
        alumniId,
        'Hi $alumniName, I would like to connect with you for mentoring and career guidance. Thank you!',
      );
      
      ref.read(toastProvider.notifier).showToast(
        'Connection request sent to $alumniName!',
        ToastType.success,
      );
    } catch (error) {
      ref.read(toastProvider.notifier).showToast(
        error.toString().replaceFirst('Exception: ', ''),
        ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: LoadingWidget(message: 'Loading Alumni Network...'),
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppTheme.glowShadow,
                        ),
                        child: const Icon(
                          Icons.people,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alumni Network',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Connect with ${_alumni.length} verified alumni from our community',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Stats
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Available Mentors',
                          _alumni.where((a) => a['mentorshipAvailable'] == true || a['isAvailableForMentorship'] == true).length.toString(),
                          AppTheme.successColor,
                          Icons.school,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Departments',
                          _getDepartments().length.toString(),
                          AppTheme.primaryColor,
                          Icons.business,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Companies',
                          _alumni.map((a) => a['currentCompany']).toSet().length.toString(),
                          AppTheme.secondaryColor,
                          Icons.work,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Search and filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find Alumni',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    ProfessionalInput(
                      controller: _searchController,
                      label: 'Search Alumni',
                      hintText: 'Search by name, company, position...',
                      prefixIcon: Icons.search,
                      onChanged: _onSearchChanged,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedDepartment.isEmpty ? null : _selectedDepartment,
                            decoration: const InputDecoration(
                              labelText: 'Department',
                              prefixIcon: Icon(Icons.business),
                            ),
                            dropdownColor: AppTheme.darkSurface,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            items: [
                              const DropdownMenuItem(
                                value: '',
                                child: Text(
                                  'All Departments',
                                  style: TextStyle(color: AppTheme.textPrimary),
                                ),
                              ),
                              ..._getDepartments().map((dept) {
                                return DropdownMenuItem(
                                  value: dept,
                                  child: Text(
                                    dept,
                                    style: const TextStyle(color: AppTheme.textPrimary),
                                  ),
                                );
                              }).toList(),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedDepartment = value ?? '');
                              _filterAlumni();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedYear.isEmpty ? null : _selectedYear,
                            decoration: const InputDecoration(
                              labelText: 'Graduation Year',
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            dropdownColor: AppTheme.darkSurface,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            items: [
                              const DropdownMenuItem(
                                value: '',
                                child: Text(
                                  'All Years',
                                  style: TextStyle(color: AppTheme.textPrimary),
                                ),
                              ),
                              ..._getGraduationYears().map((year) {
                                return DropdownMenuItem(
                                  value: year,
                                  child: Text(
                                    year,
                                    style: const TextStyle(color: AppTheme.textPrimary),
                                  ),
                                );
                              }).toList(),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedYear = value ?? '');
                              _filterAlumni();
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing ${_filteredAlumni.length} of ${_alumni.length} alumni',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        if (_searchTerm.isNotEmpty || _selectedDepartment.isNotEmpty || _selectedYear.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _searchTerm = '';
                                _selectedDepartment = '';
                                _selectedYear = '';
                              });
                              _searchController.clear();
                              _filterAlumni();
                            },
                            child: const Text(
                              'Clear Filters',
                              style: TextStyle(color: AppTheme.primaryColor),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Alumni grid
            Expanded(
              child: _filteredAlumni.isEmpty
                  ? GlassCard(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.people,
                            size: 64,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Alumni Found',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search criteria or browse all alumni.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          GradientButton(
                            onPressed: () {
                              setState(() {
                                _searchTerm = '';
                                _selectedDepartment = '';
                                _selectedYear = '';
                              });
                              _searchController.clear();
                              _filterAlumni();
                            },
                            child: const Text('Show All Alumni'),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _filteredAlumni.length,
                      itemBuilder: (context, index) {
                        final alumni = _filteredAlumni[index];
                        return _buildAlumniCard(alumni);
                      },
                    ),
            ),
          ],
        ),
        
        // Detail modal
        if (_showDetailModal && _selectedAlumni != null)
          _buildDetailModal(),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAlumniCard(Map<String, dynamic> alumni) {
    final isMentorAvailable = alumni['mentorshipAvailable'] == true ||
        alumni['isAvailableForMentorship'] == true ||
        alumni['availableForMentorship'] == true;
    
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alumni['name'] ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        alumni['currentPosition'] ?? 'Alumni',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isMentorAvailable)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppTheme.successColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailItem(
                  Icons.business,
                  alumni['department'] ?? 'Unknown',
                ),
                _buildDetailItem(
                  Icons.calendar_today,
                  'Class of ${alumni['graduationYear'] ?? 'N/A'}',
                ),
                _buildDetailItem(
                  Icons.work,
                  alumni['currentCompany'] ?? 'Not specified',
                ),
                if (alumni['location'] != null)
                  _buildDetailItem(
                    Icons.location_on,
                    alumni['location'],
                  ),
                
                const Spacer(),
                
                // Mentorship status
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isMentorAvailable 
                        ? AppTheme.successColor.withOpacity(0.1)
                        : AppTheme.textMuted.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isMentorAvailable 
                          ? AppTheme.successColor.withOpacity(0.3)
                          : AppTheme.textMuted.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isMentorAvailable ? Icons.school : Icons.person,
                        color: isMentorAvailable ? AppTheme.successColor : AppTheme.textMuted,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          isMentorAvailable ? 'Available for Mentoring' : 'Connect & Network',
                          style: TextStyle(
                            color: isMentorAvailable ? AppTheme.successColor : AppTheme.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  onPressed: () => _showAlumniDetails(alumni),
                  child: const Text(
                    'View Profile',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GradientButton(
                  onPressed: () async {
                    final uri = Uri(
                      scheme: 'mailto',
                      path: alumni['email'],
                    );
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.email, size: 12),
                      const SizedBox(width: 4),
                      const Text(
                        'Contact',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          if (widget.showConnectButton && isMentorAvailable) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                onPressed: () => _sendConnectionRequest(alumni['id'], alumni['name']),
                child: const Text(
                  'Request Mentoring',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 12),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailModal() {
    final alumni = _selectedAlumni!;
    
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxHeight: 600),
          decoration: BoxDecoration(
            color: AppTheme.darkBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.glassBorder),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alumni['name'] ?? 'Unknown',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            alumni['currentPosition'] ?? 'Alumni',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            alumni['currentCompany'] ?? 'Company not specified',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showDetailModal = false;
                          _selectedAlumni = null;
                        });
                      },
                      icon: const Icon(
                        Icons.close,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Contact info
                      _buildModalSection(
                        'Contact Information',
                        [
                          _buildModalDetailRow(Icons.email, 'Email', alumni['email']),
                          if (alumni['phoneNumber'] != null)
                            _buildModalDetailRow(Icons.phone, 'Phone', alumni['phoneNumber']),
                          if (alumni['location'] != null)
                            _buildModalDetailRow(Icons.location_on, 'Location', alumni['location']),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Academic info
                      _buildModalSection(
                        'Academic Background',
                        [
                          _buildModalDetailRow(Icons.school, 'Department', alumni['department']),
                          _buildModalDetailRow(Icons.calendar_today, 'Graduation Year', alumni['graduationYear']?.toString() ?? 'Unknown'),
                          if (alumni['batch'] != null)
                            _buildModalDetailRow(Icons.group, 'Batch', alumni['batch']),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Professional info
                      _buildModalSection(
                        'Professional Information',
                        [
                          _buildModalDetailRow(Icons.work, 'Position', alumni['currentPosition'] ?? 'Not specified'),
                          _buildModalDetailRow(Icons.business, 'Company', alumni['currentCompany'] ?? 'Not specified'),
                          if (alumni['workExperience'] != null)
                            _buildModalDetailRow(Icons.timeline, 'Experience', '${alumni['workExperience']} years'),
                        ],
                      ),
                      
                      // Bio
                      if (alumni['bio'] != null && alumni['bio'].toString().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildModalSection(
                          'About',
                          [
                            Text(
                              alumni['bio'],
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      // Skills
                      if (alumni['skills'] != null && (alumni['skills'] as List).isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildModalSection(
                          'Skills & Expertise',
                          [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: (alumni['skills'] as List).map((skill) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    skill.toString(),
                                    style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Action buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppTheme.glassBorder),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GradientButton(
                        onPressed: () {
                          setState(() {
                            _showDetailModal = false;
                            _selectedAlumni = null;
                          });
                        },
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GradientButton(
                        onPressed: () async {
                          final uri = Uri(
                            scheme: 'mailto',
                            path: alumni['email'],
                          );
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.email, size: 16),
                            const SizedBox(width: 4),
                            const Text('Send Email'),
                          ],
                        ),
                      ),
                    ),
                    if (widget.showConnectButton && (alumni['mentorshipAvailable'] == true || alumni['isAvailableForMentorship'] == true)) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: GradientButton(
                          onPressed: () => _sendConnectionRequest(alumni['id'], alumni['name']),
                          child: const Text('Request Mentoring'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildModalDetailRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 16),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Not specified',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}