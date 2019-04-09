class ShowEmailController < ApplicationController
  unloadable

  def get_day( t)
    return t.strftime "%Y-%m-%d"
  end

  def get_time(t)
    return t.strftime "%H:%M"
  end

  def datestr(event)
    dt1 = event.dtstart.value
    dt2 = event.dtend.value
    d1 = get_day(dt1)
    d2 = get_day(dt2)
    t1 = get_time(dt1)
    t2 = get_time(dt2)

    if d1 == d2
      # same day                                                                         
      "#{d1} #{t1} - #{t2}"
    else
      # different days, ignore time                                                      
      "#{d1} - #{d2}"
    end
  end


  def get_ical(email)
    email.parts.each do |p|
      if p.content_type =~ /text.calendar/
        return p.body.decoded
      end
      if p.content_type =~ /application.ics/
        return p.body.decoded
      end
    end
    nil
  end
  
  def ical_event(email)
    ical = get_ical(email)
    if ical == nil
      return nil
    end

    cals = Icalendar::Calendar.parse(ical)
    cal = cals.first
    e = cal.events.first
        

    att = e.attendee.map{|a|
       x = a.ical_params['CN']
       nm = ""
       if x != nil and x.size>0
          nm = x.first
       end
       "#{nm} <#{a.value.to}>"
     }.join(" , ")

    ret =  {
      'From' => e.organizer.ical_params['CN'].first,
      'When' => datestr(e),
      'Title' => e.summary,
      'Location' => e.location,
      'Who' => att,
      'Description' => e.description
    }
    return ret
  end

  def show
    # E.g.  /show_email/show?emailid=3
    xid = params[:emailid]
    @attachment = Attachment.find(xid)
    email = Mail.read(@attachment.diskfile)
    part =  email.html_part || email.text_part || email
    body_charset = Mail::RubyVer.pick_encoding(part.charset).to_s rescue part.charset
    plain_text_body = Redmine::CodesetUtil.to_utf8(part.body.decoded, body_charset)
    @headers = email.header.fields.map {|f| 
      [f.name, Mail::Encodings.unquote_and_convert_to(f.value, 'utf-8') ]
    }
    @content = Sanitize.fragment(plain_text_body,
                  Sanitize::Config::RELAXED)
                  
    @event = ical_event(email)

    if @event != nil
      # get a stripped html-body (without css header) so we can check the size
      elems = %w[ div table div span tr td html body p a meta h3 h4 strong i time br ]
      content2 = Sanitize.document(plain_text_body,
                                 Sanitize::Config.merge(Sanitize::Config::RELAXED,
                                                        :elements => elems))
      if content2.size > 300
        # The Calendar event is already in @content (in  html), which is
        #  the only one we want to show.
        #  Prevent double display.
        @event = nil
      end
    end
    render :template => "show_email/index", :layout => false  
  end
  
end
