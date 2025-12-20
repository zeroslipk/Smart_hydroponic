/// Validation utilities for user inputs
class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }

  // Strong password validation (for registration)
  static String? validateStrongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    
    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    if (value.trim().length > 50) {
      return 'Name must be less than 50 characters';
    }
    
    // Only allow letters, spaces, hyphens, and apostrophes
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value.trim())) {
      return 'Name can only contain letters';
    }
    
    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Numeric validation
  static String? validateNumeric(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    if (double.tryParse(value) == null) {
      return '$fieldName must be a valid number';
    }
    
    return null;
  }

  // Range validation
  static String? validateRange(
    String? value,
    String fieldName, {
    required double min,
    required double max,
  }) {
    final numericError = validateNumeric(value, fieldName);
    if (numericError != null) return numericError;
    
    final numValue = double.parse(value!);
    if (numValue < min || numValue > max) {
      return '$fieldName must be between $min and $max';
    }
    
    return null;
  }

  // Phone number validation (basic)
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional
    }
    
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(cleaned)) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }

  // Date format validation (supports multiple formats)
  static String? validateDateFormat(String? value, {String? format}) {
    if (value == null || value.trim().isEmpty) {
      return 'Date is required';
    }

    // Common date formats
    final formats = format != null 
        ? [format]
        : [
            'yyyy-MM-dd',           // ISO format: 2024-01-15
            'dd/MM/yyyy',           // European: 15/01/2024
            'MM/dd/yyyy',           // US: 01/15/2024
            'dd-MM-yyyy',           // Alternative: 15-01-2024
            'yyyy/MM/dd',           // Alternative: 2024/01/15
          ];

    for (final fmt in formats) {
      try {
        // Try to parse the date
        final parts = value.trim().split(RegExp(r'[/\-]'));
        if (parts.length != 3) continue;

        int? year, month, day;
        
        if (fmt == 'yyyy-MM-dd' || fmt == 'yyyy/MM/dd') {
          year = int.tryParse(parts[0]);
          month = int.tryParse(parts[1]);
          day = int.tryParse(parts[2]);
        } else if (fmt == 'dd/MM/yyyy' || fmt == 'dd-MM-yyyy') {
          day = int.tryParse(parts[0]);
          month = int.tryParse(parts[1]);
          year = int.tryParse(parts[2]);
        } else if (fmt == 'MM/dd/yyyy') {
          month = int.tryParse(parts[0]);
          day = int.tryParse(parts[1]);
          year = int.tryParse(parts[2]);
        }

        if (year != null && month != null && day != null) {
          // Validate ranges
          if (year < 1900 || year > 2100) {
            return 'Year must be between 1900 and 2100';
          }
          if (month < 1 || month > 12) {
            return 'Month must be between 1 and 12';
          }
          if (day < 1 || day > 31) {
            return 'Day must be between 1 and 31';
          }

          // Try to create a DateTime to validate the date
          final date = DateTime(year, month, day);
          if (date.year == year && date.month == month && date.day == day) {
            return null; // Valid date
          }
        }
      } catch (e) {
        continue; // Try next format
      }
    }

    return 'Please enter a valid date (format: ${formats.first})';
  }

  // Time format validation (HH:mm)
  static String? validateTimeFormat(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Time is required';
    }

    final timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
    if (!timeRegex.hasMatch(value.trim())) {
      return 'Please enter a valid time (format: HH:mm, e.g., 14:30)';
    }

    return null;
  }

  // DateTime validation (combines date and time)
  static String? validateDateTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Date and time is required';
    }

    // Try ISO 8601 format first
    try {
      DateTime.parse(value.trim());
      return null;
    } catch (e) {
      // Try other formats
      final dateTimeRegex = RegExp(
        r'^\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}(:\d{2})?$',
      );
      if (dateTimeRegex.hasMatch(value.trim())) {
        return null;
      }
    }

    return 'Please enter a valid date and time (format: yyyy-MM-dd HH:mm)';
  }
}
