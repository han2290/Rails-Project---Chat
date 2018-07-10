class ChatRoom < ApplicationRecord
    has_many :admissions
    has_many :users, through: :admissions
    
    has_many :chats
    
    
    after_commit :create_chat_room_notification, on: :create
    # after_commit :master_admit_room, on: :create
    # ChatRoom이 하나 만들어 지고 나면 다음 메소드를 실행한다.
    # on 뒤에는 CRUD만 들어감
    
    def user_admit_room(user) # instance method
        # ChatRoom이 하나 만들어 지고 나면 다음 메소드를 실행한다.
        Admission.create(user_id: user.id, chat_room_id: self.id)
    end
    
    # Pusher.trigger
    
    def create_chat_room_notification
        Pusher.trigger('chat_room', 'create', self.as_json)
        # (channer_name, event_name, data)
        # channer의 이름과, 이 channel에서 발생할 event_name, 그리고 이 event에 전달할 data
    end
    
end
