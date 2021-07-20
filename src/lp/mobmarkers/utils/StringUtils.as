class lp.mobmarkers.utils.StringUtils {
    
    public static function Trim(input: String, char: String):String {
        if (arguments.length < 2) {
            char = ' ';
        }
        
        var start: Number;
        var end: Number;
        
        for (start = 0; start < input.length; start++) {
            if (input.charAt(start) != char) {
                break;
            }
        }
        
        for (end = input.length; end > start; end--) {
            if (input.charAt(end - 1) != char) {
                break;
            }
        }
        
        return input.substr(start, end - start);
    }
    
}