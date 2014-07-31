

describe "element scripts" do

  it "adds a script based on default id" do
    target :script, %^
      WWW_Applet.element("#p_1").on_click("change_style", ["background-color", "#fff"]);
    ^

    actual do
      p {
        on_click :change_style, ['background-color', '#fff']
      }
    end
  end

end # === describe element scripts ===
