require 'open-uri'

class ArticlesController < ApplicationController
  def index
    @articles = Article.all
  end

  def show
    @article = Article.find(params[:id])
    @articles = Article.all
  end

  def new
    @article = Article.new
  end

  def create
    @article = Article.create(article_params)

    @article.user = current_user if current_user

    html_doc = Nokogiri::HTML(open(params[:article][:url]))
    url = params[:article][:url]

    case @article.url
    when /.bbc./
      @article.content = get_content_bbc(html_doc)
      @article.title = "[#{url[12..14].upcase}] #{get_title_bbc(html_doc)}"
      @article.date = format_date(get_date_bbc(html_doc))
    when /.france24./
      @article.content = get_content_fr(html_doc)
      @article.title = "[#{url[12..19].capitalize}] #{get_title_fr(html_doc)}"
      @article.date = format_date(get_date_fr(html_doc))
    when /.reuters./
      @article.content = get_content_reuters(html_doc)
      @article.title = "[#{url[12..18].capitalize}] #{get_title_reuters(html_doc)}"
      @article.date = format_date(get_date_reuters(html_doc))
    when /.washingtonpost./
      @article.content = get_content_wapo(html_doc)
      @article.title = "[#{url[12..21].capitalize}#{url[22..25].capitalize}] #{get_title_wapo(html_doc)}"
      @article.date = format_date(get_date_wapo(html_doc))
    when /.seattletimes./ # TODO
      # @article.content =
      # @article.title = "[#{url[12..18].capitalize}] #{get_title_seattle(html_doc)}"
      # @article.date =
    end


    if @article.save
      redirect_to article_path(@article)
    else
      render :new
    end
  end

  private

  def article_params
    params.require(:article).permit(:url, :content, :title, :date, :user_id)
  end

  # ** Beeb **
  def get_title_bbc(html_doc)
    title = html_doc.xpath("//h1").text
  end

  def get_date_bbc(html_doc)
    date = html_doc.css("div[data-datetime]")[0].text
    return date
  end

  def get_content_bbc(html_doc)
    tags = html_doc.xpath("//p")
    content = ""

    # Shaves off the beginning and end
    stop = tags.length - 5
    tags.each_with_index do |tag, index|
      if index > 11 && index < stop
        content += tag.text
        content += "\n"
      end
    end

    return content
  end

  # ** France24 **
  def get_title_fr(html_doc)
    article = html_doc.xpath("//article")
    return article.xpath("//h1").text
  end

  def get_date_fr(html_doc)
    article = html_doc.xpath("//article")
    date = html_doc.css("time[pubdate]").text # "06/01/2019 - 08:29"
    return date[0..9]
  end

  def get_content_fr(html_doc)
    tags = html_doc.xpath("//p")
    content = ""

    stop = tags.length - 13
    tags.each_with_index do |tag, index|
      if index > 0 && index < stop
        content += tag.text
        content += "\n"
      end
    end
    return content
  end

  # ** Reuters **
  def get_title_reuters(html_doc)
    return html_doc.xpath("//h1").text
  end

  def get_date_reuters(html_doc)
    date = html_doc.css("div[class='ArticleHeader_date']").text
    return date[0..14]
  end

  def get_content_reuters(html_doc)
    tags = html_doc.xpath("//p")
    content = ""

    stop = tags.length - 2
    tags.each_with_index do |tag, index|
      if index > 0 && index < stop
        content += tag.text
        content += "\n"
      end
    end
    return content
  end

  # ** Washington Post **
  def get_title_wapo(html_doc)
    return html_doc.xpath("//h1").text
  end

  def get_date_wapo(html_doc)
    date = html_doc.css("span[class='author-timestamp']").text
    # sets the date to todays if there's a problem geting the date
    date = Date.today.to_s if !date.include?("201")
  end

  def get_content_wapo(html_doc)
    article = html_doc.xpath("//article")
    tags = article.xpath("//p")
    content = ""

    stop = tags.length - 9
    tags.each_with_index do |tag, index|
      if index < stop
        content += tag.text
        content += "\n"
      end
    end
    return content
  end

  # Datetime universal format converter
  def format_date(article_date)
    date = Date.parse(article_date)
    return date.strftime('%d') + " " +
           date.strftime('%B') + ", " +
           date.strftime('%G')
  end

end
