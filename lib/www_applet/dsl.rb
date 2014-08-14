
about :a do
  a('String') {
    attrs :href=>args.first
  }
end

about :form do
  form(:Symbol) {
    attrs :method=>'post'
    input(:hidden, :_method=>args.first)
  }

  form('String', :Symbol) {
    attrs :id=>args.first, :class=>args.last
  }
end

about(:input) {
  self_close

  input!(:hidden, :Symbol, :Symbol) {
    attrs :type=>:hidden, :name=>args.second, :value=>args.third)
  }

  fieldset {
    input {
      attrs(:value=> '')
    }
  }

  fieldset(:Symbol) {
    input {
      attrs type: 'text'.freeze, name: args_of(:parent).first
    }
  }

  fieldset(:password) {
    input! {
      attrs :type=>'password'.freeze, :name=>'password'.freeze
    }
  }

  fieldset(:password, :Symbol) {
    input {
      attrs :name  => args_of(:parent).second
    }
  }

  fieldset(:password_confirm) {
    input! {
      attrs :type=>'password'.freeze, :name=>'password_confirm'.freeze, :value=>''
      on(:validate) { should_equal :password }
    }
  }

}


# -------------------------------------------------------------------
# -------------------------------------------------------------------
# -------------------------------------------------------------------
# -------------------------------------------------------------------
# -------------------------------------------------------------------
form.sign_in! {

  title "Sign-in"

  div.main {

    fieldset(:username) do
      box {
        label 'Username'
        tip 'some tip'
      }

      input {
        on(:validate){ validate "[0-9a-zA-Z.-_]{0,25}" }
      }
    end

    fieldset(:password) do
      title 'Pass phrase:'
      input
    end

    fieldset(:password_confirm) do
      title 'Confirm pass phrase:'
      input
    end
  }

  div.footer {
    div.buttons do
      submit 'Sign-in'
      cancel 'Cancel' do
        reset
        hide
      end
    end
  }

}
