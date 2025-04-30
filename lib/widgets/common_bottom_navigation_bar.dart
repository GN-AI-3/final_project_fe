// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class CommonBottomNavigationBar extends StatelessWidget {
  final bool isTrainer;
  final int currentIndex;
  final Function(int) onTap;

  const CommonBottomNavigationBar({
    Key? key,
    required this.isTrainer,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xff2746f8),
        unselectedItemColor: Colors.grey,
        currentIndex: currentIndex,
        elevation: 0,
        items: isTrainer
            ? [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today),
                  label: '일정',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.chat),
                  label: '채팅',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xff2746f8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff2746f8).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.home, color: Colors.white),
                  ),
                  label: '홈',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.description),
                  label: '계약',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.swap_horiz),
                  label: '전환',
                ),
              ]
            : [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today),
                  label: '일정',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.chat),
                  label: '채팅',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xff2746f8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff2746f8).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.home, color: Colors.white),
                  ),
                  label: '홈',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.construction),
                  label: '준비중',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.swap_horiz),
                  label: '전환',
                ),
              ],
        onTap: onTap,
      ),
    );
  }
} 