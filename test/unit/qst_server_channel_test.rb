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

require 'test_helper'

class QstServerChannelTest < ActiveSupport::TestCase
  def setup
    @chan = QstServerChannel.make :configuration => {:password => 'foo', :password_confirmation => 'foo'}
  end

  test "should not save if password is blank" do
    @chan.configuration.delete :password
    assert_false @chan.save
  end

  test "should not save if password confirmation is wrong" do
    @chan.password_confirmation = 'foo2'
    assert_false @chan.save
  end

  test "should authenticate" do
    assert @chan.authenticate('foo')
    assert_false @chan.authenticate('foo2')
  end

  test "should authenticate if save with blank password" do
    @chan.configuration = {:password => '', :password_confirmation => ''}
    @chan.save!

    @chan.reload

    assert @chan.authenticate('foo')
  end

  test "should authenticate after password changed" do
    @chan.configuration = {:password => 'foo2', :password_confirmation => 'foo2'}
    @chan.save!

    @chan.reload

    assert @chan.authenticate('foo2')
  end

  test "should update" do
    assert @chan.save
  end

  test "should validate presence of ticket if use_ticket is set to true" do
    assert @chan.valid?
    @chan.ticket_code = ''
    @chan.use_ticket = true
    assert_false @chan.valid?
  end
end
