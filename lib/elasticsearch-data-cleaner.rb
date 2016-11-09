###########################################################
###                                                     ###
### Author: Maksim Podlesnyi <mpodlesnyi@smartling.com> ###
###                                                     ###
###########################################################
require 'rubygems'
require 'json'
require 'faraday'
require 'date'


class EScleaner

  def initialize(options)
    @connection = ::Faraday.new options.url, { :request => { :timeout => options.timeout } }
    @options = options
    info()
  end

  def info
    #get ES information
    resp = @connection.get
    @es_info = parse_response resp.body
    @es_version = {}
    @es_version['major'], @es_version['minor'], @es_version['patch'] = @es_info['version']['number'].split('.').map { |i| i.to_i }
    $logger.debug("detected Elasticsearch #{@es_version['major']}.#{@es_version['minor']}")
  end

  def parse_response(response)
    j = ::JSON.parse response
    if j.has_key?('error')
      raise j['error']
    else
      j
    end
  end

  def acknowledged_test(response, answer)
    # Testing ES response for errors
    r = parse_response response.body
    if r.has_key? answer and r[answer] == true
    else
      raise 'request failed'
    end
  end

  def list
    # Get list of indices
    resp = @connection.get "_aliases"
    r = parse_response resp.body
    r.keys
  end

  def exists(index, type)
    #checks if type exists
    if @es_version['major'] >= 5
      url = "#{index}/_mapping/#{type}"
    else
      url = "#{index}/#{type}"
    end
    resp = @connection.head url
    if resp.status == 200
      return true
    elsif resp.status == 404
      return false
    else
      raise "could not check if type #{index}/#{type} exists. got response code #{resp.status}"
    end
  end

  def docs(index)
    # Returns number of documents for index
    resp = @connection.get "#{index}/_stats/docs"
    r = (parse_response resp.body)['_all']['primaries']['docs']['count']
    if r
      if r < 10
        $logger.warn("index #{index} has #{r} docs")
      end
      return r
    else
      raise "could not get count of docs for index #{index}"
    end
  end

  def delete(object)
    # Deleting indices or types
    $logger.info("deleting #{object}#{@options.dry_run ? ' (dry_run)': ''}")
    if !@options.dry_run
      resp = @connection.delete "#{object}"
      acknowledged_test resp, 'acknowledged'
    end
  end

  def optimize(index)
    # Run _optimize
    $logger.info("starting optimize for index #{index}#{@options.dry_run ? ' (dry_run)': ''}")
    if !@options.dry_run
      resp = @connection.post "#{index}/_optimize?only_expunge_deletes=true"
      failed = (parse_response resp.body)['_shards']['failed']
      if failed > 0
        $logger.warn("optimizing of index #{index} returns #{failed} failed shards")
      end
    end
  end

  def run(config)
    # Run rotate of ES data
    config.each do |pattern, settings|
      a = []
      list().each do |index|
        # check if empty just delete it
        if !@options.empty and docs(index) == 0
          delete(index)
        else
          begin
            a << DateTime.strptime(index, pattern)
          rescue
          end
        end
      end
      today = Date.today
      sorted = a.sort
      while sorted.length > 0
        need_to_optimize = false
        date = sorted.pop
        d = date.to_date
        index = date.strftime(pattern)
        if d > today
          if settings['future'] == false
            $logger.debug("going to delete index #{index}. It is future")
            delete(index)
          end
        else
          if settings['number']
            if settings['number'] <= 0
              delete(index)
            else
              if settings['types']
                # Checking types settings
                settings['types'].each do |type, type_settings|
                  if exists(index, type)
                    if type_settings['number']
                      if type_settings['number'] <= 0
                        delete("#{index}/#{type}")
                        if type_settings['optimize'] and need_to_optimize == false
                          need_to_optimize = true
                        end
                      else
                        type_settings['number'] -= 1
                      end
                    end
                  end
                end
              end
            end
            settings['number'] -= 1
          end
        end
        a.delete(date)
        # do optimize if needed
        if need_to_optimize
          optimize(index)
        end
      end
    end
  end
end

