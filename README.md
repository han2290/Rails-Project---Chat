# Day 22

### 템플릿 적용

1. 먼저 해당 Template에 사용된 Bootstrap 버전을 확인한다. 최근 3버전에서 4버전으로 업데이트 되었기 때문에 버전에 맞춰 진행하는 것이 중요하다. 해당 버전에 맞춰서 Gem을 설치한다.

2. 설치된 Gem들을 사용할 수 있게 설정하는 것

3. 사용할 Template 파일에서 사용하고 있는 stylesheet 파일들을 확인하고 vendor/assets/stylesheet에 복사&붙여넣기 한다.

   > vendor 폴더를 사용하는 이유는 여기에 들어가는 css와 js는 거의 변화가 없는 library 저옫에 해당하는 파일이 들어간다. 변화할 파일들(custom.css/style.css)은 app/assets/stylesheet 에 넣어둔다.

4. app/assets/stylesheet/application.css -> scss로 확장자를 바꾸고 우리가 vendor에 넣어둔 파일들을 전부 `@import` 한다. 기존에 있던 *= 형태로 되어있는 import는 전부 제거한다.

5. 동일한 형태로 js도 진행한다.(파일 복사) 새로운 컨트롤러가 만들어질 때 coffee 스크립트가 적용되는데 이 확장자도 js로 바꾸어 준다. `//= requrie tree`는 삭제하고 application.js에서는 bootstrap과 jquery 혹은 모든 페이지에서 공통되는 js만 import한다.

6. config/initializers/assets.rb에서 `Rails.application.config.assets.precompile`를 주석해제 하고 우리가 사용할 컨트롤러에 해당하는 js와 scss 파일명을 나열한다.

7. `$ rake assets:precompile`을 실행해서 scss 파일과 js 파일에 이상이 없는지 확인한다. 이상이 있는 부분은 css, js에 맞춰서 수정한다.

8. 이제 실제 body에 해당하는 부분을 우리 페이지로 가져오면 되는데, nav, footer는 파일을 분리하는 것이 좋다. 반복적으로 사용될 친구들인데 이 친구들은 render(partial)을 이용해서 view를 분리하는게 좋습니다. 그래서 필요한 부분에 가져다 사용하면 된다.

9. 실제로 우리가 만든 view에는 본인 서비스가 제공되는 페이지이자 로직이 들어간다.

10. js의 경우에는 대부분 문서 제일 마지막에 들어가는데 이 부분을 해결하기 위해서 `yield 'content_name'`과 `content_for 'content_name'`과 같은 전략을 사용한다.

11. 1~5번 까지 작성했던 js파일과 scss 파일을 실제 뷰에서 사용하기 위해서 `stylesheet_link_tag`와 `javascript_include_tag`에 각 컨트롤러에 맞는 파일을 가져오기 위해서 `params[:controller]`라는 매개변수를 주어 각 컨트롤러마다 다른 scss와 js가 적용되도록 한다.

12. 이 모든 것을 asset_pipeline이라고 하는데, 이는 페이지를 더 빠르게 로드하기 위한 전략으로 사용된다.



## Pusher

#### Chat

* Gem 추가

  > Gemfile
  >
  > ```ruby
  > # pusher
  > gem 'pusher'
  > 
  > # authantication
  > gem 'devise'
  > 
  > # key encrypt
  > gem 'figaro'
  > ```

* devise, scaffold, model 생성

  > command
  >
  > ```
  > $ rails g devise:install
  > $ rails g devise users
  > 
  > $ rails g scaffold chat_rooms
  > 
  > $ rails g model admission
  > $ rails g model chat
  > ```

* Model 관계 설정

  > migrate 속성 설정
  >
  > ```ruby
  > #Admission
  > class CreateAdmissions < ActiveRecord::Migration[5.0]
  >   def change
  >     create_table :admissions do |t|
  >       t.references      :chat_room
  >       t.references      :user
  >       
  >       t.timestamps
  >     end
  >   end
  > end
  > 
  > #Chat_room
  > class CreateChatRooms < ActiveRecord::Migration[5.0]
  >   def change
  >     create_table :chat_rooms do |t|
  >       t.string        :title
  >       t.string        :master_id
  >       
  >       t.integer       :max_count
  >       t.integer       :admissions_count, defauls: 0
  >       
  >       t.timestamps
  >     end
  >   end
  > end
  > 
  > #Chat
  > class CreateChats < ActiveRecord::Migration[5.0]
  >   def change
  >     create_table :chats do |t|
  >       t.references      :user
  >       t.references      :chat_room
  >       
  >       t.text            :message
  >       
  >       
  >       t.timestamps
  >     end
  >   end
  > end
  > ```

* Model 관계 설정

  > 각 Model file
  >
  > ```ruby
  > #Admission_model
  > class Admission < ApplicationRecord
  >     belongs_to :user
  >     belongs_to :chat_room, counter_cache: true
  > end
  > 
  > #chat_room_model
  > class ChatRoom < ApplicationRecord
  >     has_many :admissions
  >     has_many :users, through: :admissions
  >     
  >     has_many :chats
  > end
  > 
  > #chat_model
  > class Chat < ApplicationRecord
  >     belongs_to :user
  >     belongs_to :chat_room
  > end
  > 
  > #user_model
  > class User < ApplicationRecord
  >   # Include default devise modules. Others available are:
  >   # :confirmable, :lockable, :timeoutable and :omniauthable
  >   devise :database_authenticatable, :registerable,
  >          :recoverable, :rememberable, :trackable, :validatable
  >          
  >   has_many :admissions
  >   has_many :chat_rooms, through: :admissions
  >   has_many :chats
  > end
  > ```

* chat_room이 생성되면 관계된 admission도 instance가 생성되어야 한다. 따라서 chat_room에 instance method를 선언해준다.

  > chat_room model
  >
  > ```ruby
  > def user_admit_room(user) # instance method
  >     # ChatRoom이 하나 만들어 지고 나면 다음 메소드를 실행한다.
  >     Admission.create(user_id: user.id, chat_room_id: self.id)
  > end
  > ```

* `$ figaro install` 명령으로 figaro 환경변수 파일을 생성한다.

* figaro를 이용해서 환경 변수를 설정한다. 그리고 설정한 기 값들을 이니셜라이져에 pusher.rb 파일을 만들어서 다음과 같이 저장시켜 준다.

  ```ruby
  require 'pusher'
  
  Pusher.app_id = ENV["pusher_app_id"]
  Pusher.key = ENV["pusher_key"]
  Pusher.secret = ENV["pusher_scret"]
  Pusher.cluster = ENV["pusher_cluster"]
  Pusher.logger = Rails.logger
  Pusher.encrypted = true
  ```

* ChatRoom model에 다음과 같이 코드를 추가한다.

  > chat_rooms model
  >
  > ```ruby
  > after_commit :create_chat_room_notification, on: :create    
  > def create_chat_room_notification
  >     Pusher.trigger('chat_room', 'create', self.as_json)
  >     # (channer_name, event_name, data)
  >     # channer의 이름과, 이 channel에서 발생할 event_name, 그리고 이 event에 전달할 data
  > end
  > ```
  >
  >  Pusher의 클래스 메소드인 `trigger`를 이용해 특정 채널인 `chat_room`의 `create`이벤트를 발생시키는 트리거를 작성한다. 이 트리거의 조건은 `chat_room`의 instance가 생성된 이후가 된다(즉, db에서 commit이 되고 난 후).

* index에서 채널과 이벤트를 선언해 준다.

  > index.html
  >
  > ```ruby
  > var pusher = new Pusher("<%=ENV["pusher_key"]%>", {
  >     cluster: "<%= ENV["pusher_cluster"] %>",
  >     encrypted: true
  >   });
  > 
  > var channel = pusher.subscribe('chat_room');
  > 	channel.bind('create', function(data) {
  >     console.log(data);
  >   });
  > ```
  >
  >  figaro를 이용해 선언한 환경 변수를 가져와서 pusher instance를 생성시 파라메터로 넣어준다. 그리고 채널을 pusher instance method를 이용해 chat_room 채널과 create 이벤트를 생성해 준다.

* show에서 접속중인 유저들의 목록을 보여준다.

  > show.html.erb
  >
  > ```erb
  > <%= current_user.email %>
  > <h3>현재 접속한 사람</h3>
  > <div class="joined_user_list">
  > <% @chat_room.users.each do |user|%>
  > <p><%= user.email %></p>
  > <% end %>
  > </div>
  > <hr>
  > <% unless @chat_room.users.include?(current_user)%>
  > <%= link_to 'Join', join_chat_room_path(@chat_room), method: "post", class: "join_room", remote: true %> |
  > <% end %>
  > <%= link_to 'Edit', edit_chat_room_path(@chat_room) %> |
  > <%= link_to 'Back', chat_rooms_path %>
  > 
  > <script>
  > $(document).on('ready', function(){  
  >   function user_joined(data) {
  >       $('.joined_user_list').append(`<p>${data.email}</p>`)
  >       var joinroom = $('.join_room')
  >       console.log(data.email+"/"+"<%=current_user.email%>")
  >       
  >       if(data.email=="<%=current_user.email%>"){
  >           $('.join_room').remove();
  >       }
  >   }
  >     
  >   var pusher = new Pusher("<%=ENV["pusher_key"]%>", {
  >     cluster: "<%= ENV["pusher_cluster"] %>",
  >     encrypted: true
  >   });
  >   var channel = pusher.subscribe('chat_room');
  >   channel.bind('join', function(data) {
  >     console.log(data);
  >     user_joined(data);
  >   }); 
  > });
  > </script>
  > ```
  >
  > 



## 기타

#### pusher

* pusher 서버는 외부에 존재함
* pusher instance method인 `subcribe`를 사용할 경우 pusher 서버에 채널과 이벤트를 생성.
* 따라서 모델에서 trigger를 통해 외부의 pusher 서버를 통해 존재하는 특정 채널의 특정 이벤트에 데이터를 넘겨준다.
* 그럼 채널은 이미 정의된 이벤트를 전달받은 데이터를 기반으로 진행하게 된다.



#### remote: true

```erb
<%= link_to 'Join', join_chat_room(@chat_room), method: "post", remote: true %>
```

 만약에 `remote: true`를 사용하지 않는다면, 별도의 뷰가 필요없는 위 명령어를 위해 ajax 코드를 별도로 작성하여야 할 것이다. 하지만 `remote: true`를 사용하면 이 코드가 ajax로 동작하게끔 할 수 있다.



#### coffee script



#### Atlassian

 참고

