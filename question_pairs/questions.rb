require 'sqlite3'
require 'singleton'

class QuestionsDBConnection < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class User
  attr_reader :fname, :lname

  def self.all
    data = QuestionsDBConnection.instance.execute(<<-SQL)
    SELECT
      *
    FROM
      users
    SQL

    data.map { |datum| Question.new(datum) }
  end

  def self.find_by_id(id)
    user = QuestionsDBConnection.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?;
    SQL
    return nil unless user.empty?
    User.new(user.first)
  end

  def self.find_by_name(fname, lname)
    user = QuestionsDBConnection.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        users
      WHERE
        fname = ? AND lname = ?
    SQL
    return nil unless user.empty?
    User.new(user.first)
  end

  def initialize(options)
    @fname = options['fname']
    @lname = options['lname']
    @id = options['id']
  end

  def create
    raise "#{self} already in database" if @id
    QuestionsDBConnection.instance.execute(<<-SQL, @fname, @lname)
    INSERT INTO
      users (fname, lname)
    VALUES
      ( ?, ?)
    SQL
    @id = QuestionsDBConnection.instance.last_insert_row_id
  end

  def update
    raise "#{self} not in database" unless @id
    QuestionsDBConnection.instance.execute(<<-SQL, @fname, @lname, @id)
    UPDATE
      users
    SET
      fname = ?, lname = ?
    WHERE
      id = ?
    SQL
  end

  def authored_questions
    Question.find_by_author_id(@id)
  end

  def authored_replies
    Reply.find_by_user_id(@id)
  end

  def followed_questions
    QuestionFollow.followed_questions_for_user_id(@id)
  end
end



  class Question
    attr_accessor :title, :body, :author_id

    def self.all
      data = QuestionsDBConnection.instance.execute(<<-SQL)
      SELECT
        *
      FROM
        questions
      SQL

      data.map {|datum| Question.new(datum)}
    end

    def self.find_by_author_id(a_id)
      data = QuestionsDBConnection.instance.execute(<<-SQL, a_id)
      SELECT
        *
      FROM
        questions
      WHERE
        author_id = ?
      SQL
      return nil if data.empty?
      data.map { |datum| Question.new(datum) }
    end

    def self.find_by_id(id)
      question = QuestionsDBConnection.instance.execute(<<-SQL, id)
        SELECT
          *
        FROM
          questions
        WHERE
          id = ?;
      SQL
      return nil unless question.length > 0
      Question.new(question.first)
    end

    def self.find_by_title(title)
      question = QuestionsDBConnection.instance.execute(<<-SQL, title)
        SELECT
          *
        FROM
          questions
        WHERE
          title = ?
      SQL
      return nil unless question.length > 0
      Question.new(question.first)
    end


    def initialize(options)
      @id = options['id']
      @title = options['title']
      @body = options['body']
      @author_id = options['author_id']
    end

    def author
      result = QuestionsDBConnection.instance.execute(<<-SQL, @author_id)
      SELECT
        fname,lname
      FROM
        users
      WHERE
        id = ?
      SQL

      result
    end

    def replies
      Reply.find_by_question_id(@id)
    end

    def create
      raise "#{self} already in database" if @id
      QuestionsDBConnection.instance.execute(<<-SQL, @title, @body, @author_id)
      INSERT INTO
        questions (title, body, author_id)
      VALUES
        (?, ?, ?)
      SQL

      @id = QuestionsDBConnection.instance.last_insert_row_id
    end

    def update
      raise "#{self} already in database" unless @id
      QuestionsDBConnection.instance.execute(<<-SQL, @title, @body, @author_id, @id)
      UPDATE
        questions
      SET
        title = ?, body = ?, author_id = ?
      WHERE
        id = ?
      SQL
    end

    def followers
      QuestionFollow.followers_for_question_id(@id)
    end

  end

  class QuestionFollow
    attr_accessor :user_id, :question_id

    def self.all
      data = QuestionsDBConnection.instance.execute(<<-SQL)
      SELECT
        *
      FROM
        question_follows
      SQL

      data.map {|datum| QuestionFollow.new(datum)}
    end

    def self.find_by_question_id(q_id)
      question_followers = QuestionsDBConnection.instance.execute(<<-SQL, q_id)
      SELECT
        *
      FROM
        question_follows
      WHERE
        question_id = ?
      SQL
      return nil unless question_followers.length > 0

      question_followers.map { |datum| QuestionFollow.new(datum) }
    end

    def self.followers_for_question_id(q_id)
      data = QuestionsDBConnection.instance.execute(<<-SQL, q_id)
      SELECT
        *
      FROM
        question_follows
        LEFT JOIN users ON users.id = question_follows.user_id
      WHERE
        question_id = ?
      SQL

     data.map { |datum| User.new(datum) }
    end

    def self.followed_questions_for_user_id(u_id)
      data = QuestionsDBConnection.instance.execute(<<-SQL, u_id)
      SELECT
        questions.*
      FROM
        question_follows
        LEFT JOIN questions ON questions.id = question_follows.question_id
      WHERE
        user_id = ?
      SQL

     data.map { |datum| Question.new(datum) }
    end

    def self.find_by_user_id(u_id)
      data = QuestionsDBConnection.instance.execute(<<-SQL, u_id)
      SELECT
        *
      FROM
        question_follows
      WHERE
        user_id = ?
      SQL

      return nil if data.empty?
      data.map { |datum| QuestionFollow.new(datum) }
    end

    def initialize(options)
      @user_id = options['user_id']
      @question_id = options['question_id']
    end

    def name
      result = QuestionsDBConnection.instance.execute(<<-SQL, @user_id)
      SELECT
        fname,lname
      FROM
        users
      WHERE
        id = ?
      SQL

      result
    end

    def create
      raise "#{self} already in database" if @id
      QuestionsDBConnection.instance.execute(<<-SQL, @user_id, @question_id)
      INSERT INTO
        question_follows (user_id,question_id)
      VALUES
        (?, ?)
      SQL

      @id = QuestionsDBConnection.instance.last_insert_row_id
    end

    def update
      raise "#{self} already in database" unless @id
      QuestionsDBConnection.instance.execute(<<-SQL, @user_id, @question_id, @id)
      UPDATE
        question_follows
      SET
        user_id = ?, question_id = ?
      WHERE
        id = ?
      SQL
    end
  end

  class QuestionLike
    attr_accessor :user_id, :question_id

    def self.all
      data = QuestionsDBConnection.instance.execute(<<-SQL)
      SELECT
        *
      FROM
        question_likes
      SQL

      data.map {|datum| QuestionLike.new(datum)}
    end

    def self.find_by_question_id(q_id)
      question_likes = QuestionsDBConnection.instance.execute(<<-SQL, q_id)
      SELECT
        *
      FROM
        question_likes
      WHERE
        question_id = ?
      SQL
      return nil unless question_likes.length > 0

      question_likes.map { |datum| QuestionLike.new(datum) }
    end

    def self.find_by_user_id(u_id)
      data = QuestionsDBConnection.instance.execute(<<-SQL, u_id)
      SELECT
        *
      FROM
        question_likes
      WHERE
        user_id = ?
      SQL

      return nil if data.empty?
      data.map { |datum| QuestionLike.new(datum) }
    end

    def initialize(options)
      @user_id = options['user_id']
      @question_id = options['question_id']
    end

    def name
      result = QuestionsDBConnection.instance.execute(<<-SQL, @user_id)
      SELECT
        fname,lname
      FROM
        users
      WHERE
        id = ?
      SQL

      result
    end

    def create
      raise "#{self} already in database" if @id
      QuestionsDBConnection.instance.execute(<<-SQL, @user_id, @question_id)
      INSERT INTO
        question_likes (user_id,question_id)
      VALUES
        (?, ?)
      SQL

      @id = QuestionsDBConnection.instance.last_insert_row_id
    end

    def update
      raise "#{self} already in database" unless @id
      QuestionsDBConnection.instance.execute(<<-SQL, @user_id, @question_id, @id)
      UPDATE
        question_likes
      SET
        user_id = ?, question_id = ?
      WHERE
        id = ?
      SQL
    end
  end

class Reply
    attr_accessor :question_id, :parent_id, :user_id, :reply_body

  def self.all
    data = QuestionsDBConnection.instance.execute(<<-SQL)
    SELECT
      *
    FROM
      replies
    SQL
    data.map { |datum| Reply.new(datum) }
  end

  def initialize(options)
    @question_id = options['question_id']
    @parent_id = options['parent_id']
    @user_id = options['user_id']
    @reply_body = options['reply_body']
  end

  def self.find_by_question_id(q_id)
    result = QuestionsDBConnection.instance.execute(<<-SQL, q_id)
    SELECT
      *
    FROM
      replies
    WHERE
      question_id = ?
    SQL

    return nil if result.empty?
    result.map {|datum| Reply.new(datum)}
  end

  def self.find_by_parent_id(p_id)
    result = QuestionsDBConnection.instance.execute(<<-SQL, p_id)
    SELECT
      *
    FROM
      replies
    WHERE
      parent_id = ?
    SQL

    return nil if result.empty?
    result.map {|datum| Reply.new(datum)}
  end


  def self.find_by_user_id(u_id)
    result = QuestionsDBConnection.instance.execute(<<-SQL, u_id)
    SELECT
      *
    FROM
      replies
    WHERE
      user_id = ?
    SQL

    return nil if result.empty?
    result.map {|datum| Reply.new(datum)}
  end


  def author
    result = QuestionsDBConnection.instance.execute(<<-SQL, @user_id)
    SELECT
      fname,lname
    FROM
      users
    WHERE
      id = ?
    SQL

    result
  end


  def question
    result = QuestionsDBConnection.instance.execute(<<-SQL, @user_id)
    SELECT
      title, body
    FROM
      questions
    WHERE
      id = ?
    SQL

    result
  end

  def parent_reply
    result = QuestionsDBConnection.instance.execute(<<-SQL, @parent_id)
    SELECT
      reply_body
    FROM
      replies
    WHERE
      id = ?
    SQL

    result
  end


  def parent_reply
    result = QuestionsDBConnection.instance.execute(<<-SQL, @id)
    SELECT
      reply_body
    FROM
      replies
    WHERE
      parent_id = ?
    SQL

    result
  end


  def create
    QuestionsDBConnection.instance.execute(<<-SQL, @question_id, @parent_id, @user_id, @reply_body)
      INSERT INTO
        replies(question_id, parent_id,user_id,reply_body)
      VALUES
        (?,?,?,?)
    SQL

    @id = QuestionsDBConnection.instance.last_insert_row_id
  end

  def update
    QuestionsDBConnection.instance.execute(<<-SQL, @question_id, @parent_id, @user_id, @reply_body, @id)
    UPDATE
      replies
    SET
      question_id = ?, parent_id = ?, user_id = ?, reply_body = ?
    WHERE
      id = ?
    SQL
  end
end
