require 'sqlite3'
require 'singleton'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end






class User
    attr_accessor :id, :fname, :lname

    def self.find_by_id(id)
        data = QuestionsDatabase.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                users
            WHERE
                id = ?
        SQL
        return nil unless data.length > 0
        User.new(data.first)
    end

    def self.find_by_name(fname, lname)
        data = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
            SELECT
                *
            FROM
                users
            WHERE
                fname = ? AND lname = ?
        SQL
        return nil unless data.length > 0
        data.map { |datum| User.new(data) }
    end

    def initialize(options)
        @id = options['id']
        @fname = options['fname']
        @lname = options['lname']
    end

    def authored_questions
        Question.find_by_author_id(id)
    end

    def authored_replies
        Reply.find_by_user_id(id)
    end

    def followed_questions
        QuestionFollow.followed_questions_for_user_id(id)
    end

    def liked_questions
        QuestionLike.liked_questions_for_user_id(id)
    end

    def average_karma
        data = QuestionsDatabase.instance.execute(<<-SQL, id)
            SELECT
                CAST(COUNT(question_likes.question_id) AS FLOAT) /
                COUNT(DISTINCT(questions.id)) as average
              
            FROM
                questions
            LEFT OUTER JOIN
                question_likes ON questions.id = question_likes.question_id
            WHERE
                questions.author_id = ?
        SQL

        # return 0 unless data.length > 0
        data.first
    end

    def save
        if self.id.nil? 
            QuestionsDatabase.instance.execute(<<-SQL, self.fname, self.lname)
            INSERT INTO
                users (fname, lname)
            VALUES
                (?, ?)
            SQL
            self.id = QuestionsDatabase.instance.last_insert_row_id
        else
            QuestionsDatabase.instance.execute(<<-SQL, fname, lname, id)
            UPDATE
                users
            SET
                fname = ?, lname = ?
            WHERE
                id = ?
            SQL
       end
    end

end





class Question
    attr_accessor :id, :title, :body, :author_id

    def self.find_by_id(id)
        data = QuestionsDatabase.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                questions
            WHERE
                id = ?
        SQL
        return nil unless data.length > 0
        Question.new(data.first)
    end

    def self.find_by_author_id(author_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, author_id)
            SELECT
                *
            FROM
                questions
            WHERE
                author_id = ?
        SQL
        return nil unless data.length > 0
        data.map { |datum| Question.new(datum) }
    end

    def most_followed(n)
        QuestionFollow.most_followed_questions(n)
    end

    def most_liked(n)
        QuestionLike.most_liked_questions(n)
    end


    def initialize(options)
        @id = options['id']
        @title = options['title']
        @body = options['body']
        @author_id = options['author_id']
    end

    def author
        User.find_by_id(author_id)
    end

    def replies
        Reply.find_by_question_id(id)
    end

    def followers
        QuestionFollow.followers_for_question_id(id)
    end

    def likers
        QuestionLike.likers_for_question_id(id)
    end

    def num_likes
        QuestionLike.num_likes_for_question_id(id)
    end
end





class Reply
    attr_accessor :id, :question_id, :parent_id, :user_id, :body

    def self.find_by_id(id)
        data = QuestionsDatabase.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                replies
            WHERE
                id = ?
        SQL
        return nil unless data.length > 0
        Reply.new(data.first)
    end

    def self.find_by_user_id(user_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, user_id)
            SELECT
                *
            FROM
                replies
            WHERE
                user_id = ?
        SQL
        return nil unless data.length > 0
        data.map { |datum| Reply.new(datum) }
    end

    def self.find_by_question_id(question_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
            SELECT
                *
            FROM
                replies
            WHERE
                question_id = ?
        SQL
        return nil unless data.length > 0
        data.map { |datum| Reply.new(datum) }
    end

    def initialize(options)
        @id = options['id']
        @question_id = options['question_id']
        @parent_id = options['parent_id']
        @user_id = options['user_id']
        @body = options['body']
    end

    def author
        User.find_by_id(user_id)
    end

    def question
        Question.find_by_id(question_id)
    end

    def parent_reply
        Reply.find_by_id(parent_id)
    end

    def child_replies
        data = QuestionsDatabase.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                replies
            WHERE
                parent_id = ?
        SQL
        return nil unless data.length > 0
        data.map { |datum| Reply.new(datum) }
    end
end




class QuestionFollow
    attr_accessor :question_id, :user_id

    def self.followers_for_question_id(question_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
            SELECT
                users.*
            FROM
                users
            JOIN
                question_follows ON users.id = question_follows.user_id
            WHERE
                question_id = ?
        SQL
        return nil unless data.length > 0
        data.map { |datum| User.new(datum) }
    end

    def self.followed_questions_for_user_id(user_id)
         data = QuestionsDatabase.instance.execute(<<-SQL, user_id)
            SELECT
                questions.*
            FROM
                questions
            JOIN
                question_follows ON questions.id = question_follows.question_id
            WHERE
                user_id = ?
        SQL
        return nil unless data.length > 0
        data.map { |datum| Question.new(datum) }
    end

    def self.most_followed_questions(n)
        data = QuestionsDatabase.instance.execute(<<-SQL, n)
            SELECT
                questions.*
            FROM
                question_follows
            JOIN
                questions ON questions.id = question_id
            GROUP BY
                question_id
            ORDER BY
                COUNT(*) DESC
            LIMIT ?
        SQL
        return nil unless data.length > 0
        data.map { |datum| Question.new(datum) }
    end

    def initialize(options)
        @question_id = options['question_id']
        @user_id = options['user_id']
    end
end

class QuestionLike
    attr_accessor :question_id, :user_id

    def self.likers_for_question_id(question_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
            SELECT
                users.*
            FROM
                users
            JOIN
                question_likes ON users.id = question_likes.user_id
            WHERE
                question_id = ?
        SQL
        return nil unless data.length > 0
        data.map { |datum| User.new(datum) }
    end

    def self.num_likes_for_question_id(question_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
            SELECT
                COUNT(*) as count
            FROM
                question_likes
            WHERE
                question_id = ?
        SQL
        return 0 unless data.length > 0
        data.first['count']
    end

    def self.liked_questions_for_user_id(user_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, user_id)
            SELECT
                questions.*
            FROM
                questions
            JOIN 
                question_likes ON questions.id = question_id
            WHERE
                user_id = ?
        SQL
        return nil unless data.length > 0
        data.map { |datum| Question.new(datum) }
    end

    def self.most_liked_questions(n)
        data = QuestionsDatabase.instance.execute(<<-SQL, n)
            SELECT
                questions.*
            FROM
                question_likes
            JOIN
                questions ON questions.id = question_id
            GROUP BY
                question_id
            ORDER BY
                COUNT(*) DESC
            LIMIT ?
        SQL
        return nil unless data.length > 0
        data.map { |datum| Question.new(datum) }
    end

    def initialize(options)
        @question_id = options['question_id']
        @user_id = options['user_id']
    end
end

