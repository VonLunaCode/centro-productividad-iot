import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/profile.dart';

class ProfileChip extends StatelessWidget {
  final Profile profile;
  final bool isSelected;
  final VoidCallback onTap;

  const ProfileChip({
    super.key,
    required this.profile,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.18)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected
                ? Colors.white.withOpacity(0.6)
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          profile.name,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : Colors.white60,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
