/// JavaScript for saving and restoring how far a page is scrolled.
abstract final class ScrollScripts {
  /// Evaluates to the vertical scroll position in CSS pixels.
  static const String read =
      '(function(){'
      'var d=document.documentElement,b=document.body;'
      'return window.pageYOffset||(d&&d.scrollTop)||(b&&b.scrollTop)||0;'
      '})()';

  /// Scrolls to [y]. A page that has not grown tall enough yet is retried up to
  /// five times, 300 ms apart, and scrolled as far as it goes after that.
  static String restore(double y) {
    final int target = y.isFinite && y > 0 ? y.round() : 0;
    return '(function(){'
        'var t=$target,n=0;'
        'function go(){'
        'var d=document.documentElement;'
        'var h=Math.max(d?d.scrollHeight:0,document.body?document.body.scrollHeight:0);'
        'if(h>=t+window.innerHeight||n>=5){window.scrollTo(0,t);return;}'
        'n++;setTimeout(go,300);'
        '}'
        'go();'
        '})()';
  }

  /// Reads a result of [read] as a scroll position. Anything that is not a
  /// finite non-negative number is 0.
  static double parse(Object? value) =>
      value is num && value.isFinite && value >= 0 ? value.toDouble() : 0;
}
