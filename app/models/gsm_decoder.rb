class GsmDecoder
 
 @@base_charset =  %W[@ £ $ ¥ è é ù ì ò Ç \x0a Ø ø \x0d Å å]
 @@base_charset += %W[Δ _ Φ Γ Λ Ω Π Ψ Σ Θ Ξ ` Æ æ ß É]
 @@base_charset += %W[\x20 ! " # ¤ % & ' ( ) * = , - . / ]
 @@base_charset += %W[0 1 2 3 4 5 6 7 8 9 : ; < = > ?]
 @@base_charset += %W[¡ A B C D E F G H I J K L M N O]
 @@base_charset += %W[P Q R S T U V W X Y Z Ä Ö Ñ Ü `]
 @@base_charset += %W[¿ a b c d e f g h i j k l m n o]
 @@base_charset += %W[p q r s t u v w x y z ä ö ñ ü à]
 
 def self.decode(str)
   converted = ""
   i = 0
   while i < str.length do
     c = str[i]
     i += 1
     if c != 0x1b
       converted << @@base_charset[c] || '*'
     else
       converted << case str[i]
       when 0x14: '^'
       when 0x28: '{'
       when 0x29: '}'
       when 0x2f: '\\'
       when 0x3c: '['
       when 0x3d: '~'
       when 0x3e: ']'
       when 0x40: '|'
       when 0x65: '€'
       else '*'
       end
       i += 1
     end
   end
   converted
 end
 
end