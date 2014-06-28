

title "All about me."

style(
  :p => {
    "background-color" => "#665"
  }
)

p( :id=>"my_text", :title=>"idk") do

  form(:id=>"guestbook", :to=>"/my/guestbook") do
    button(:class=>"submit") { "Go" }
  end


  form(:id=>"friend-enemy", :to=>"/my/friend-enemy") do
    splash_line "Hiya!"
    button(:class=>"submit") { "Go" }
  end

  %^
    The end.
  ^

end # === p

splash_line 'hello' do
  div "hello" do
    div "goodbye"
  end
end
