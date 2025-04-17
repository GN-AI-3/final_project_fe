class KoreanPostposition {
  static String getPostposition(String text) {
    if (text.isEmpty) return '로';
    
    // 마지막 글자의 유니코드
    final lastChar = text.codeUnitAt(text.length - 1);
    
    // 한글의 경우
    if (lastChar >= 0xAC00 && lastChar <= 0xD7A3) {
      // 받침이 있는지 확인 (한글 유니코드에서 받침은 마지막 3비트)
      final hasFinalConsonant = (lastChar - 0xAC00) % 28 != 0;
      return hasFinalConsonant ? '으로' : '로';
    }
    
    // 한글이 아닌 경우 기본값
    return '로';
  }
} 