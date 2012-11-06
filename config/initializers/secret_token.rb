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

# Be sure to restart your server when you modify this file.

if defined? Nuntium
  # Be sure to restart your server when you modify this file.

  # Your secret key for verifying the integrity of signed cookies.
  # If you change this key, all old signed cookies will become invalid!
  # Make sure the secret is at least 30 characters and all random,
  # no regular words or you'll be exposed to dictionary attacks.
  Nuntium::Application.config.secret_token = 'deb0fbd88b5fc0e98b397cf74c1eb3ac1705706f521d958cbacd74e861b765dd6b75dcaa1dca71572059e26e78dce67f6cd64170a7459e73714cef3edbe77c39'
end
