import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rishai/core/extensions/build_context_extension.dart';
import 'package:rishai/core/router/app_navigation_service.dart';
import 'package:rishai/core/router/app_routes.dart';
import 'package:rishai/core/widgets/new_button.dart';
import 'package:rishai/core/widgets/rish_scaffold.dart';
import 'package:rishai/core/widgets/snackbar.dart';
import 'package:rishai/features/settings/domain/repository/feedback_repository_impl.dart';
import 'package:rishai/features/settings/domain/usecase/send_feedback_usecase.dart';
import 'package:rishai/features/user/presentation/bloc/user_bloc.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  String? _selectedSubject = 'feedback';
  List<XFile> _attachedMediaList = [];
  bool _isSendButtonEnabled = false;
  bool _isLoading = false;

  final List<String> _subjects = [
    'feedback',
    'tech support',
    'payments',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_updateSendButtonState);
    _emailController.addListener(_updateSendButtonState);
    _messageController.addListener(_updateSendButtonState);
  }

  @override
  void dispose() {
    _nameController.removeListener(_updateSendButtonState);
    _emailController.removeListener(_updateSendButtonState);
    _messageController.removeListener(_updateSendButtonState);
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _updateSendButtonState() {
    setState(() {
      _isSendButtonEnabled = _nameController.text.isNotEmpty &&
          _emailController.text.isNotEmpty &&
          _messageController.text.isNotEmpty;
    });
  }

  Future<void> _pickMedia() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> media =
        await picker.pickMultipleMedia(requestFullMetadata: false);

    if (media.isNotEmpty) {
      int currentTotalSize = _attachedMediaList.fold(
        0,
        (sum, item) => sum + File(item.path).lengthSync(),
      );
      List<XFile> newlySelectedValid = [];
      int newlySelectedSize = 0;

      for (final item in media) {
        final fileBytes = await item.readAsBytes();
        final fileSizeInMB = fileBytes.lengthInBytes / (1024 * 1024);
        if (fileSizeInMB <= 10) {
          if ((currentTotalSize + newlySelectedSize + fileBytes.lengthInBytes) /
                  (1024 * 1024) <=
              50) {
            newlySelectedValid.add(item);
            newlySelectedSize += fileBytes.lengthInBytes;
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Total attachment size limit (50MB) exceeded.'),
              ),
            );
            break;
          }
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File "${item.name}" is too large (Max 10MB).'),
            ),
          );
        }
      }

      setState(() {
        _attachedMediaList.addAll(newlySelectedValid);
        if (_attachedMediaList.length > 5) {
          _attachedMediaList =
              _attachedMediaList.sublist(_attachedMediaList.length - 5);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 5 attachments allowed.')),
          );
        }
      });
    } else {
      // User canceled the picker
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _attachedMediaList.removeAt(index);
    });
  }

  Future<void> _sendFeedback() async {
    setState(() {
      _isLoading = true;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (!_isSendButtonEnabled) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final name = _nameController.text;
    final email = _emailController.text;
    final subject = _selectedSubject;
    final message = _messageController.text;
    final List<File> attachments = [];

    print('Name: $name');
    print('Email: $email');
    print('Subject: $subject');
    print('Message: $message');
    print('Attachments Count: ${attachments.length}');
    for (final attachment in _attachedMediaList) {
      File file = File(attachment.path);
      attachments.add(file);
      // print('  - Path: ${attachment.path}, Name: ${attachment.name}');
    }

    final res = await SendFeedbackUseCase(feedbackRepository).call(
      SendFeedbackParams(
        name: name,
        email: email,
        subject: subject!,
        message: message,
        attachments: attachments,
        userId: userBloc.state.user.directusId,
      ),
    );

    res.fold(
      (failure) => RishSnackbar().showSnackBar(
        'Failed to send feedback, please try again.',
      ),
      (success) => RishSnackbar().showSnackBar(
        'Feedback sent successfully!',
        isError: false,
      ),
    );

    _formKey.currentState?.reset();
    setState(() {
      _selectedSubject = 'feedback';
      // _attachedMediaList.clear();
      _isSendButtonEnabled = false;
      _isLoading = false;
    });
    Future.delayed(const Duration(seconds: 1), () {
      appNavigationService.pop(path: AppRoutes.homeScreen.path);
    });
  }

  Widget _buildPreviewItem(XFile file, int index) {
    bool isImage = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp']
        .any((ext) => file.path.toLowerCase().endsWith(ext));

    return Stack(
      alignment: Alignment.topRight,
      children: [
        Container(
          margin: const EdgeInsets.all(4),
          width: 80.w,
          height: 80.w,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isImage
                ? Image.file(
                    File(file.path),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 40),
                  )
                : ColoredBox(
                    color: Colors.grey.shade200,
                    child: Icon(
                      Icons.videocam,
                      size: 40,
                      color: Colors.grey.shade600,
                    ),
                  ),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: InkWell(
            onTap: () => _removeMedia(index),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return RishScaffold(
      needsAppBar: true,
      appBarLabel: Text(
        'Contact Us',
        style: context.styles.h1,
      ),
      implyLeading: true,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(255),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedSubject,
                        decoration: const InputDecoration(labelText: 'Subject'),
                        items: _subjects.map((String subject) {
                          return DropdownMenuItem<String>(
                            value: subject,
                            child: Text(
                              subject[0].toUpperCase() + subject.substring(1),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedSubject = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a subject';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your message';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      // RishButton.primary(
                      //   title: 'Attach Media',
                      //   enabled: true,
                      //   isLoading: false,
                      //   action: _pickMedia,
                      // ),
                      // if (_attachedMediaList.isNotEmpty)
                      //   Padding(
                      //     padding: const EdgeInsets.only(top: 16),
                      //     child: Wrap(
                      //       spacing: 8,
                      //       runSpacing: 8,
                      //       children: _attachedMediaList
                      //           .asMap()
                      //           .entries
                      //           .map(
                      //             (entry) =>
                      //                 _buildPreviewItem(entry.value, entry.key),
                      //           )
                      //           .toList(),
                      //     ),
                      //   ),
                      // const SizedBox(height: 32),
                      RishButton.primary(
                        title: 'Send',
                        enabled: _isSendButtonEnabled,
                        isLoading: _isLoading,
                        action: _sendFeedback,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
