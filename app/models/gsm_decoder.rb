# coding: utf-8

# Copyright (C) 2009-2012, InSTEDD
# 
# This file is part of Nuntium.
# 
# Nuntium is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# Nuntium is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Nuntium.  If not, see <http://www.gnu.org/licenses/>.

require 'iconv'

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
     c = str[i].ord
     i += 1
     if c != 0x1b
       converted << (@@base_charset[c] || '*')
     else
       converted << case str[i].ord
       when 0x14 then '^'
       when 0x28 then '{'
       when 0x29 then '}'
       when 0x2f then '\\'
       when 0x3c then '['
       when 0x3d then '~'
       when 0x3e then ']'
       when 0x40 then '|'
       when 0x65 then '€'
       else '*'
       end
       i += 1
     end
   end
   converted
 end

end
