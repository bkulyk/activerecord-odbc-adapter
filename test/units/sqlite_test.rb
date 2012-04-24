require 'minitest/autorun'
require 'rubygems'
require "active_record"
require 'awesome_print'

ActiveRecord::Base.establish_connection(
    # adapter: 'mysql2',
    # socket: '/var/run/mysqld/mysqld.sock',
    # encoding: "utf8",
    # database: "ar_odbc_adapter_test",
    
    adapter: 'odbc',
    dsn: 'ar_odbc_adapter_test',
      
    pool: 5,
    username: 'root',
    password: 'pass'
  )
  
class Movie < ActiveRecord::Base
end

class SqliteTest < MiniTest::Unit::TestCase
  
  def setup
    begin
      ActiveRecord::Base.connection.execute "DROP TABLE movies"
      ActiveRecord::Base.connection.execute "DROP TABLE actors"
    rescue
      #do nothing
    end
    
    # sql = "CREATE TABLE movies ( id INTEGER PRIMARY KEY ASC, title TEXT, year INTEGER )"
    sql = "CREATE TABLE IF NOT EXISTS `movies` (
    `id` int(10) NOT NULL AUTO_INCREMENT,
    `title` varchar(255) NOT NULL,
    `year` int(10) NOT NULL,
    PRIMARY KEY (`id`) )"
    r = ActiveRecord::Base.connection.execute sql
    
    sql = "CREATE TABLE IF NOT EXISTS `actors` (
    `id` int(10) NOT NULL AUTO_INCREMENT,
    `firstname` varchar(255) NOT NULL,
    `lastname` varchar(255) NOT NULL,
    PRIMARY KEY (`id`) )"
    r = ActiveRecord::Base.connection.execute sql
  end
  
  def test_primary_key
    pk = ActiveRecord::Base.connection.primary_key 'movies'
    self.assert_equal 'id', pk
  end
  
  def test_tables
    tables = ActiveRecord::Base.connection.tables
    self.assert tables.include? 'movies'
    self.assert tables.include? 'actors'
  end
  
  def test_drop_table
    before = ActiveRecord::Base.connection.tables.size
    
    ActiveRecord::Base.connection.drop_table 'movies'
    after = ActiveRecord::Base.connection.tables.size
    assert after < before
    
    ActiveRecord::Base.connection.drop_table 'actors'
    later = ActiveRecord::Base.connection.tables.size
    assert later < after
  end
  
  def test_last_insert_id
    # assert_equal 'ActiveRecord::ConnectionAdapters::ODBCAdapter', ActiveRecord::Base.connection.class.name
    return unless ActiveRecord::Base.connection.class.name == 'ActiveRecord::ConnectionAdapters::ODBCAdapter'
    
    sql = "INSERT INTO movies VALUES( null, '?', '?' )"

    binds = [ 'Commando', 1985 ] #actually watching Commando Right now.
    ActiveRecord::Base.connection.execute( sql, binds )
    id = ActiveRecord::Base.connection.last_insert_id 'movies', 'insert'
    
    # TODO find out if this is really supposed to be an integer, 
    #  because it's comming out as a string
    assert_equal 1, id.to_i
    
    binds = [ 'Terminator', 1984 ]
    ActiveRecord::Base.connection.execute( sql, binds )
    id = ActiveRecord::Base.connection.last_insert_id 'movies', 'insert'
    
    assert_equal 2, id.to_i
  end
  
  def test_mysql_should_not_respond_to_pre_insert
    
    return unless ActiveRecord::Base.connection.adapter_name == 'ODBC'
    return unless ActiveRecord::Base.connection.dbmsName == :mysql
    # return unless ActiveRecord::Base.connection
        
    self.refute ActiveRecord::Base.connection.respond_to? 'pre_insert'
  end
  
  def test_insert_sql
    sql = "INSERT INTO `movies` (`id`, `title`, `year`) VALUES ('?', '?', '?')"
    binds = [ 0,'Batman Begins', 2005 ]
    
    ActiveRecord::Base.connection.execute sql, binds
    # assert_equal 1, id
    
    sql = "INSERT INTO `movies` (`id`, `title`, `year`) VALUES (?, ?, ?)"
    binds = [ 0,'The Dark Knight', 2008 ]

    id = ActiveRecord::Base.connection.insert_sql( sql, nil, 'id', nil, nil, binds )
    assert_equal 2, id
  end
  
  def test_create doassert=true
    m = Movie.create title: 'Highlander', year: '1986'
    assert 1, m.id if doassert
    
    m = Movie.create title: 'Highlander II: The Quickening', year: 1991
    assert_equal 2, m.id if doassert

    Movie.create title: 'Predator 2', year: 1990
    Movie.create title: 'Teenage Mutant Ninja Turtles', year: 1990
  end
  
  def test_select_all
    test_create false
    
    x = ActiveRecord::Base.connection.select_all( 'SELECT * FROM movies', [] )
    res = x.map { |m| m['title'] }
    
    assert_equal 4, res.size
    assert res.include? 'Predator 2' #for example
  end
  
  def test_select_one
    test_create false
    
    res = ActiveRecord::Base.connection.select_one( 'SELECT * FROM movies where id = ?', [4] )
    assert_equal 'Teenage Mutant Ninja Turtles', res['title']
  end
  
  # def test_find
    # test_create false
#     
    # a = Movie.find 2
    # assert_equal 1991, a.year
#     
    # b = Movie.find 1
    # assert_equal 'Highlander', b.title
  # end
#   
  # def test_find_by_match
    # test_create false
#     
    # t = 'Teenage Mutant Ninja Turtles'
    # a = Movie.find_by_title t
    # assert_equal 1990, a.year
    # assert_equal t, a.title
  # end
#   
  # def test_find_all_by_match
    # test_create false
#     
    # all = Movie.find_all_by_year 1990
    # assert_equal 2, all.size
#     
    # titles = all.map { |x| x.title }
    # assert titles.include? 'Teenage Mutant Ninja Turtles'
    # assert titles.include? 'Predator 2'
  # end
#   
end