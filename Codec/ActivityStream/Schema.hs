{-# LANGUAGE Rank2Types #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}

{-|
Module      : Codec.ActivityStream.Schema
Description : An interface to the Activity Streams Base Schema
Copyright   : (c) Getty Ritter, 2014
Maintainer  : gdritter@galois.com

This is an interface to the extended ActivityStreams schema which defines
an extensive set of @verb@ values, additional @objectType@ values, and a
set of extended properties for 'Object's.

Most of the inline documentation is drawn directly from the
<https://github.com/activitystreams/activity-schema/blob/master/activity-schema.md Activity Base Schema draft>
specification, with minor modifications
to refer to the corresponding data types in this module and to clarify
certain aspects. This is not an approved draft, and as such may be
subject to changes which will be reflected in this module. In contrast to
"Codec.ActivityStream", the API in this module makes
__no guarantees about long-term stability__.
-}

module Codec.ActivityStream.Schema
  ( module Codec.ActivityStream
  -- * Verbs
  , SchemaVerb(..)
  -- * Object Types
  , SchemaObjectType(..)
  -- ** Audio/Video
  , avEmbedCode
  , avStream
  -- ** Binary
  , bnCompression
  , bnData
  , bnFileUrl
  , bnLength
  , bnMd5
  , bnMimeType
  -- ** Event
  , evAttendedBy
  , evAttending
  , evEndTime
  , evInvited
  , evMaybeAttending
  , evNotAttendedBy
  , evNotAttending
  , evStartTime
  -- ** Issue
  , isTypes
  -- ** Permission
  , pmScope
  , pmActions
  -- ** Place
  , plPosition
  , plAddress
  -- *** PlacePosition
  , PlacePosition
  -- *** PlaceAddress
  , PlaceAddress
  -- ** Role/Group
  , rlMembers
  -- ** Task
  , tsActor
  , tsBy
  , tsObject
  , tsPrerequisites
  , tsRequired
  , tsSupersedes
  , tsVerb
  -- * Basic Extension Properties
  , acContext
  , getLocation
  , oMood
  , oRating
  , acResult
  , getSource
  , getStartTime
  , getEndTime
  , oTags
    -- * Mood
  , Mood
  , moodRest
  , moodDisplayName
  , moodImage
  ) where

import qualified Data.Aeson as Aeson
import           Data.Aeson.TH (deriveJSON)
import           Data.Time.Clock (UTCTime)
import           Data.Aeson ( FromJSON(..), ToJSON(..) )
import qualified Data.HashMap.Strict as HM
import           Data.Text (Text)

import Codec.ActivityStream.Internal
import Codec.ActivityStream.LensInternal
import Codec.ActivityStream

-- | The ActivityStreams Base Schema specification defines the
-- following core verbs in addition to the default post verb that is
-- defined in Section 6 of activitystreams:
data SchemaVerb
  = Accept
    -- ^ Indicates that that the actor has accepted the object.
    -- For instance, a person accepting an award, or accepting an assignment.
  | Access
    -- ^ Indicates that the actor has accessed the object. For
    -- instance, a person accessing a room, or accessing a file.
  | Acknowledge
    -- ^ Indicates that the actor has acknowledged the object.
    -- This effectively signals that the actor is aware of the
    -- object's existence.
  | Add
    -- ^ Indicates that the actor has added the object to the target.
    -- For instance, adding a photo to an album.
  | Agree
    -- ^ Indicates that the actor agrees with the object. For example,
    -- a person agreeing with an argument, or expressing agreement
    -- with a particular issue.
  | Append
    -- ^ Indicates that the actor has appended the object to the
    -- target. For instance, a person appending a new record
    -- to a database.
  | Approve
    -- ^ Indicates that the actor has approved the object. For
    -- instance, a manager might approve a travel request.
  | Archive
    -- ^ Indicates that the actor has archived the object.
  | Assign
    -- ^ Indicates that the actor has assigned the object to the target.
  | At
    -- ^ Indicates that the actor is currently located at the object.
    -- For instance, a person being at a specific physical location.
  | Attach
    -- ^ Indicates that the actor has attached the object to the
    -- target. For instance, a person attaching a file to a wiki
    -- page or an email.
  | Attend
    -- ^ Indicates that the actor has attended the object. For
    -- instance, a person attending a meeting.
  | Author
    -- ^ Indicates that the actor has authored the object. Note that
    -- this is a more specific form of the verb \"create\".
  | Authorize
    -- ^ Indicates that the actor has authorized the object. If
    -- a target is specified, it means that the authorization is specifically
    -- in regards to the target. For instance, a service can authorize a
    -- person to access a given application; in which case the actor is
    -- the service, the object is the person, and the target is the
    -- application. In contrast, a person can authorize a request; in
    -- which case the actor is the person and the object is the request
    -- and there might be no explicit target.
  | Borrow
    -- ^ Indicates that the actor has borrowed the object. If a target
    -- is specified, it identifies the entity from which the object was
    -- borrowed. For instance, if a person borrows a book from a library,
    -- the person is the actor, the book is the object and the library is
    -- the target.
  | Build
    -- ^ Indicates that the actor has built the object. For example, if a
    -- person builds a model or compiles code.
  | Cancel
    -- ^ Indicates that the actor has canceled the object. For instance,
    -- canceling a calendar event.
  | Close
    -- ^ Indicates that the actor has closed the object. For instance, the
    -- object could represent a ticket being tracked in an issue management
    -- system.
  | Complete
    -- ^ Indicates that the actor has completed the object.
  | Confirm
    -- ^ Indicates that the actor has confirmed or agrees with the object.
    -- For instance, a software developer might confirm an issue reported
    -- against a product.
  | Consume
    -- ^ Indicates that the actor has consumed the object. The specific
    -- meaning is dependent largely on the object's type. For instance,
    -- an actor may \"consume\" an audio object, indicating that the actor
    -- has listened to it; or an actor may \"consume\" a book, indicating
    -- that the book has been read. As such, the \"consume\" verb is a
    -- more generic form of other more specific verbs such as \"read\" and
    -- \"play\".
  | Checkin
    -- ^ Indicates that the actor has checked-in to the object. For
    -- instance, a person checking-in to a Place.
  | Create
    -- ^ Indicates that the actor has created the object.
  | Delete
    -- ^ Indicates that the actor has deleted the object. This implies,
    -- but does not require, the permanent destruction of the object.
  | Deliver
    -- ^ Indicates that the actor has delivered the object. For example,
    -- delivering a package.
  | Deny
    -- ^ Indicates that the actor has denied the object. For example, a
    -- manager may deny a travel request.
  | Disagree
    -- ^ Indicates that the actor disagrees with the object.
  | Dislike
    -- ^ Indicates that the actor dislikes the object. Note that the
    -- \"dislike\" verb is distinct from the \"unlike\" verb which assumes
    -- that the object had been previously \"liked\".
  | Experience
    -- ^ Indicates that the actor has experienced the object in some
    -- manner. Note that, depending on the specific object types used for
    -- both the actor and object, the meaning of this verb can overlap
    -- that of the \"consume\" and \"play\" verbs. For instance, a person
    -- might \"experience\" a movie; or \"play\" the movie; or \"consume\"
    -- the movie. The \"experience\" verb can be considered a more generic
    -- form of other more specific verbs as \"consume\", \"play\", \"watch\",
    -- \"listen\", and \"read\"
  | Favorite
    -- ^ Indicates that the actor marked the object as an item of special
    -- interest.
  | Find
    -- ^ Indicates that the actor has found the object.
  | FlagAsInappropriate
    -- ^ Indicates that the actor has flagged the object as being
    -- inappropriate for some reason. When using this verb, the context
    -- property can be used to provide additional detail about why the
    -- object has been flagged.
  | Follow
    -- ^ Indicates that the actor began following the activity of the
    -- object. In most cases, the objectType will be a \"person\", but it
    -- can potentially be of any type that can sensibly generate activity.
    -- Processors MAY ignore (silently drop) successive identical \"follow\"
    -- activities.
  | Give -- ^ Indicates that the actor is giving an object to the
    -- target. Examples include one person giving a badge object to another
    -- person. The object identifies the object being given. The target
    -- identifies the receiver.
  | Host
    -- ^ Indicates that the actor is hosting the object. As in hosting
    -- an event, or hosting a service.
  | Ignore
    -- ^ Indicates that the actor has ignored the object. For
    -- instance, this verb may be used when an actor has ignored a friend
    -- request, in which case the object may be the request-friend activity.
  | Insert
    -- ^ Indicates that the actor has inserted the object into the target.
  | Install
    -- ^ Indicates that the actor has installed the object, as in installing
    -- an application.
  | Interact
    -- ^ Indicates that the actor has interacted with the object. For
    -- instance, when one person interacts with another.
  | Invite
    -- ^ Indicates that the actor has invited the object, typically a
    -- person object, to join or participate in the object described
    -- by the target. The target could, for instance, be an event,
    -- group or a service.
  | Join
    -- ^ Indicates that the actor has become a member of the
    -- object. This specification only defines the meaning of this
    -- verb when the object of the Activity has an objectType of
    -- group, though implementors need to be prepared to handle other
    -- types of objects.
  | Leave
    -- ^ Indicates that the actor has left the object. For instance, a
    -- Person leaving a Group or checking-out of a Place.
  | Like
    -- ^ Indicates that the actor marked the object as an item of
    -- special interest. The \"like\" verb is considered to be an alias
    -- of \"favorite\". The two verb are semantically identical.
  | Listen
    -- ^ Indicates that the actor has listened to the object. This is
    -- typically only applicable for objects representing audio
    -- content, such as music, an audio-book, or a radio
    -- broadcast. The \"listen\" verb is a more specific form of the
    -- \"consume\", \"experience\" and \"play\" verbs.
  | Lose
    -- ^ Indicates that the actor has lost the object. For instance,
    -- if a person loses a game.
  | MakeFriend
    -- ^ Indicates the creation of a friendship that is reciprocated
    -- by the object. Since this verb implies an activity on the part
    -- of its object, processors MUST NOT accept activities with this
    -- verb unless they are able to verify through some external means
    -- that there is in fact a reciprocated connection. For example, a
    -- processor may have received a guarantee from a particular
    -- publisher that the publisher will only use this Verb in cases
    -- where a reciprocal relationship exists.
  | Open
    -- ^ Indicates that the actor has opened the object. For instance,
    -- the object could represent a ticket being tracked in an issue
    -- management system.
  | Play
    -- ^ Indicates that the actor spent some time enjoying the
    -- object. For example, if the object is a video this indicates
    -- that the subject watched all or part of the video. The \"play\"
    -- verb is a more specific form of the \"consume\" verb.
  | Post
    -- ^ The default action.
  | Present
    -- ^ Indicates that the actor has presented the object. For
    -- instance, when a person gives a presentation at a conference.
  | Purchase
    -- ^ Indicates that the actor has purchased the object. If a
    -- target is specified, in indicates the entity from which the
    -- object was purchased.
  | Qualify
    -- ^ Indicates that the actor has qualified for the object. If a
    -- target is specified, it indicates the context within which the
    -- qualification applies.
  | Read
    -- ^ Indicates that the actor read the object. This is typically
    -- only applicable for objects representing printed or written
    -- content, such as a book, a message or a comment. The \"read\"
    -- verb is a more specific form of the \"consume\", \"experience\" and
    -- \"play\" verbs.
  | Receive
    -- ^ Indicates that the actor is receiving an object. Examples
    -- include a person receiving a badge object. The object
    -- identifies the object being received.
  | Reject
    -- ^ Indicates that the actor has rejected the object.
  | Remove
    -- ^ Indicates that the actor has removed the object from the target.
  | RemoveFriend
    -- ^ Indicates that the actor has removed the object from the
    -- collection of friends.
  | Replace
    -- ^ Indicates that the actor has replaced the target with the object.
  | Request
    -- ^ Indicates that the actor has requested the object. If a
    -- target is specified, it indicates the entity from which the
    -- object is being requested.
  | RequestFriend
    -- ^ Indicates the creation of a friendship that has not yet been
    -- reciprocated by the object.
  | Resolve
    -- ^ Indicates that the actor has resolved the object. For
    -- instance, the object could represent a ticket being tracked in
    -- an issue management system.
  | Return
    -- ^ Indicates that the actor has returned the object. If a target
    -- is specified, it indicates the entity to which the object was
    -- returned.
  | Retract
    -- ^ Indicates that the actor has retracted the object. For
    -- instance, if an actor wishes to retract a previously published
    -- activity, the object would be the previously published activity
    -- that is being retracted.
  | RsvpMaybe
    -- ^ The \"possible RSVP\" verb indicates that the actor has made a
    -- possible RSVP for the object. This specification only defines
    -- the meaning of this verb when its object is an event, though
    -- implementors need to be prepared to handle other object
    -- types. The use of this verb is only appropriate when the RSVP
    -- was created by an explicit action by the actor. It is not
    -- appropriate to use this verb when a user has been added as an
    -- attendee by an event organiser or administrator.
  | RsvpNo
    -- ^ The \"negative RSVP\" verb indicates that the actor has made a
    -- negative RSVP for the object. This specification only defines
    -- the meaning of this verb when its object is an event, though
    -- implementors need to be prepared to handle other object
    -- types. The use of this verb is only appropriate when the RSVP
    -- was created by an explicit action by the actor. It is not
    -- appropriate to use this verb when a user has been added as an
    -- attendee by an event organiser or administrator.
  | RsvpYes
    -- ^ The \"positive RSVP\" verb indicates that the actor has made a
    -- positive RSVP for an object. This specification only defines
    -- the meaning of this verb when its object is an event, though
    -- implementors need to be prepared to handle other object
    -- types. The use of this verb is only appropriate when the RSVP
    -- was created by an explicit action by the actor. It is not
    -- appropriate to use this verb when a user has been added as an
    -- attendee by an event organiser or administrator.
  | Satisfy
    -- ^ Indicates that the actor has satisfied the object. If a
    -- target is specified, it indicate the context within which the
    -- object was satisfied. For instance, if a person satisfies the
    -- requirements for a particular challenge, the person is the
    -- actor; the requirement is the object; and the challenge is the
    -- target.
  | Save
    -- ^ Indicates that the actor has called out the object as being
    -- of interest primarily to him- or herself. Though this action
    -- MAY be shared publicly, the implication is that the object has
    -- been saved primarily for the actor's own benefit rather than to
    -- show it to others as would be indicated by the \"share\" verb.
  | Schedule
    -- ^ Indicates that the actor has scheduled the object. For
    -- instance, scheduling a meeting.
  | Search
    -- ^ Indicates that the actor is or has searched for the
    -- object. If a target is specified, it indicates the context
    -- within which the search is or has been conducted.
  | Sell
    -- ^ Indicates that the actor has sold the object. If a target is
    -- specified, it indicates the entity to which the object was
    -- sold.
  | Send
    -- ^ Indicates that the actor has sent the object. If a target is
    -- specified, it indicates the entity to which the object was
    -- sent.
  | Share
    -- ^ Indicates that the actor has called out the object to
    -- readers. In most cases, the actor did not create the object
    -- being shared, but is instead drawing attention to it.
  | Sponsor
    -- ^ Indicates that the actor has sponsored the object. If a
    -- target is specified, it indicates the context within which the
    -- sponsorship is offered. For instance, a company can sponsor an
    -- event; or an individual can sponsor a project; etc.
  | Start
    -- ^ Indicates that the actor has started the object. For
    -- instance, when a person starts a project.
  | StopFollowing
    -- ^ Indicates that the actor has stopped following the object.
  | Submit
    -- ^ Indicates that the actor has submitted the object. If a
    -- target is specified, it indicates the entity to which the
    -- object was submitted.
  | Tag
    -- ^ Indicates that the actor has associated the object with the
    -- target. For example, if the actor specifies that a particular
    -- user appears in a photo. the object is the user and the target
    -- is the photo.
  | Terminate
    -- ^ Indicates that the actor has terminated the object.
  | Tie
    -- ^ Indicates that the actor has neither won or lost the
    -- object. This verb is generally only applicable when the object
    -- represents some form of competition, such as a game.
  | Unfavorite
    -- ^ Indicates that the actor has removed the object from the
    -- collection of favorited items.
  | Unlike
    -- ^ Indicates that the actor has removed the object from the
    -- collection of liked items.
  | Unsatisfy
    -- ^ Indicates that the actor has not satisfied the object. If a
    -- target is specified, it indicates the context within which the
    -- object was not satisfied. For instance, if a person fails to
    -- satisfy the requirements of some particular challenge, the
    -- person is the actor; the requirement is the object and the
    -- challenge is the target.
  | Unsave
    -- ^ Indicates that the actor has removed the object from the
    -- collection of saved items.
  | Unshare
    -- ^ Indicates that the actor is no longer sharing the object. If
    -- a target is specified, it indicates the entity with whom the
    -- object is no longer being shared.
  | Update
    -- ^ The \"update\" verb indicates that the actor has modified the
    -- object. Use of the \"update\" verb is generally reserved to
    -- indicate modifications to existing objects or data such as
    -- changing an existing user's profile information.
  | Use
    -- ^ Indicates that the actor has used the object in some manner.
  | Watch
    -- ^ Indicates that the actor has watched the object. This verb is
    -- typically applicable only when the object represents dynamic,
    -- visible content such as a movie, a television show or a public
    -- performance. This verb is a more specific form of the verbs
    -- \"experience\", \"play\" and \"consume\".
  | Win
    -- ^ Indicates that the actor has won the object. This verb is
    -- typically applicable only when the object represents some form
    -- of competition, such as a game.
    deriving (Eq, Show, Read)

deriveJSON (commonOptsCC "") ''SchemaVerb

-- | This data type contains the core set of common objectTypes in addition
-- to the "activity" objectType defined in Section 7 of
-- activitystreams.
--
-- All Activity Stream Objects inherit the same
-- fundamental set of basic properties as defined in section 3.4 of
-- activitystreams. In addition to these, objects of any specific type
-- are permitted to introduce additional optional or required
-- properties that are meaningful to objects of that type.
data SchemaObjectType
  = Alert
    -- ^ Represents any kind of significant notification.
  | Application
    -- ^ Represents any kind of software application.
  | Article
    -- ^ Represents objects such as news articles, knowledge base
    -- entries, or other similar construct. Such objects generally
    -- consist of paragraphs of text, in some cases incorporating
    -- embedded media such as photos and inline hyperlinks to other
    -- resources.
  | Audio
    -- ^ Represents audio content of any kind. Objects of this type
    -- MAY contain an additional property as specified
    -- <https://github.com/activitystreams/activity-schema/blob/master/activity-schema.md#audio-video here>.
  | Badge
    -- ^ Represents a badge or award granted to an object (typically a
    -- @person@ object)
  | Binary
    -- ^ Objects of this type are used to carry arbirary
    -- Base64-encoded binary data within an Activity Stream object. It
    -- is primarily intended to attach binary data to other types of
    -- objects through the use of the @attachments@ property. Objects
    -- of this type will contain the additional properties specified
    -- <https://github.com/activitystreams/activity-schema/blob/master/activity-schema.md#binary here>.
  | Bookmark
    -- ^ Represents a pointer to some URL -- typically a web page. In
    -- most cases, bookmarks are specific to a given user and contain
    -- metadata chosen by that user. Bookmark Objects are similar in
    -- principle to the concept of bookmarks or favorites in a web
    -- browser. A bookmark represents a pointer to the URL, not the
    -- URL or the associated resource itself. Objects of this type
    -- SHOULD contain an additional @targetUrl@ property whose value
    -- is a String containing the IRI of the target of the bookmark.
  | Collection
    -- ^ Represents a generic collection of objects of any type. This
    -- object type can be used, for instance, to represent a
    -- collection of files like a folder; a collection of photos like
    -- an album; and so forth. Objects of this type MAY contain an
    -- additional @objectTypes@ property whose value is an Array of
    -- Strings specifying the expected objectType of objects contained
    -- within the collection.
  | Comment
    -- ^ Represents a textual response to another object. Objects of
    -- this type MAY contain an additional @inReplyTo@ property whose
    -- value is an Array of one or more other Activity Stream Objects
    -- for which the object is to be considered a response.
  | Device
    -- ^ Represents a device of any type.
  | Event
    -- ^ Represents an event that occurs at a certain location during
    -- a particular period of time. Objects of this type MAY contain
    -- the additional properties specified
    -- <https://github.com/activitystreams/activity-schema/blob/master/activity-schema.md#event here>.
  | File
    -- ^ Represents any form of document or file. Objects of this type
    -- MAY contain an additional @fileUrl@ property whose value a
    -- dereferenceable IRI that can be used to retrieve the file; and
    -- an additional @mimeType@ property whose value is the MIME type
    -- of the file described by the object.
  | Game
    -- ^ Represents a game or competition of any kind.
  | Group
    -- ^ Represents a grouping of objects in which member objects can
    -- join or leave. Objects of this type MAY contain the additional
    -- properties specified
    -- <https://github.com/activitystreams/activity-schema/blob/master/activity-schema.md#roleGroup here>.
  | Image
    -- ^ Represents a graphical image. Objects of this type MAY
    -- contain an additional @fullImage@ property whose value is an
    -- Activity Streams Media Link to a "full-sized" representation of
    -- the image.
  | Issue
    -- ^ Represents a report about a problem or situation that needs
    -- to be resolved. For instance, the @issue@ object can be used to
    -- represent reports detailing software defects, or reports of
    -- acceptable use violations, and so forth. Objects of this type
    -- MAY contain the additional properties specified
    -- <https://github.com/activitystreams/activity-schema/blob/master/activity-schema.md#issue here>.
  | Job
    -- ^ Represents information about a job or a job posting.
  | Note
    -- ^ Represents a short-form text message. This object is intended
    -- primarily for use in "micro-blogging" scenarios and in systems
    -- where users are invited to publish short, often plain-text
    -- messages whose useful lifespan is generally shorter than that
    -- of an article of weblog entry. A note is similar in structure
    -- to an article, but typically does not have a title or distinct
    -- paragraphs and tends to be much shorter in length.
  | Offer
    -- ^ Represents an offer of any kind.
  | Organization
    -- ^ Represents an organization of any kind.
  | Page
    -- ^ Represents an area, typically a web page, that is
    -- representative of, and generally managed by a particular
    -- entity. Such areas are usually dedicated to displaying
    -- descriptive information about the entity and showcasing recent
    -- content such as articles, photographs and videos. Most social
    -- networking applications, for example, provide individual users
    -- with their own dedicated "profile" pages. Several allow similar
    -- types of pages to be created for commercial entities,
    -- organizations or events. While the specific details of how
    -- pages are implemented, their characteristics and use may vary,
    -- the one unifying property is that they are typically "owned" by
    -- a single entity that is represented by the content provided by
    -- the page itself.
  | Permission
    -- ^ Represents a permission that can be granted to an
    -- individual. For instance, a person can be granted permission to
    -- modify a file. Objects of this type MAY contain the additional
    -- properties specified
    -- <https://github.com/activitystreams/activity-schema/blob/master/activity-schema.md#permissions here>.
  | Person
    -- ^ Represents an individual person.
  | Place
    -- ^ Represents a physical location. Locations can be represented
    -- using geographic coordinates, a physical address, a free-form
    -- location name, or any combination of these. Objects of this
    -- type MAY contain the additional properties specified
    -- <https://github.com/activitystreams/activity-schema/blob/master/activity-schema.md#place here>.
  | Process
    -- ^ Represents any form of process. For instance, a long-running
    -- task that is started and expected to continue operating for a
    -- period of time.
  | Product
    -- ^ Represents a commercial good or service. Objects of this type
    -- MAY contain an additional @fullImage@ property whose value is
    -- an Activity Streams Media Link to an image resource
    -- representative of the product.
  | Question
    -- ^ Represents a question or a poll. Objects of this type MAY
    -- contain an additional @options@ property whose value is an
    -- Array of possible answers to the question in the form of
    -- Activity Stream objects of any type.
  | Review
    -- ^ Represents a primarily prose-based commentary on another
    -- object. Objects of this type MAY contain a @rating@ property as
    -- specified
    -- <https://github.com/activitystreams/activity-schema/blob/master/activity-schema.md#rating-property here>.
  | Service
    -- ^ Represents any form of hosted or consumable service that
    -- performs some kind of work or benefit for other
    -- entities. Examples of such objects include websites,
    -- businesses, etc.
  | Task
    -- ^ Represents an activity that has yet to be completed. Objects
    -- of this type can contain additional properties as specified
    -- here.
  | Team
    -- ^ Represents a team of any type.
  | Video
    -- ^ Represents video content of any kind. Objects of this type
    -- MAY contain additional properties as specified here.
    deriving (Eq, Show, Read)

deriveJSON (commonOptsCC "") ''SchemaObjectType


-- audio/video

-- | A fragment of HTML markup that, when embedded within another HTML
--   page, provides an interactive user-interface for viewing or listening
--   to the video or audio stream.
avEmbedCode :: Lens' Object (Maybe Text)
avEmbedCode = makeAesonLensMb "embedCode" oRest

-- | An Activity Streams Media Link to the video or audio content itself.
avStream :: Lens' Object (Maybe MediaLink)
avStream = makeAesonLensMb "stream" oRest

-- binary

-- | An optional token identifying a compression algorithm applied to
--   the binary data prior to Base64-encoding. Possible algorithms
--   are "deflate" and "gzip", respectively indicating the use of
--   the compression mechanisms defined by RFC 1951 and RFC 1952.
--   Additional compression algorithms MAY be used but are not defined
--   by this specification. Note that previous versions of this
--   specification allowed for multiple compression algorithms to be
--   applied and listed using a comma-separated format. The use of
--   multiple compressions is no longer permitted.
bnCompression :: Lens' Object (Maybe Text)
bnCompression = makeAesonLensMb "compression" oRest

-- | The URL-Safe Base64-encoded representation of the binary data
bnData :: Lens' Object (Maybe Text)
bnData = makeAesonLensMb "data" oRest
-- | An optional IRI for the binary data described by this object.
bnFileUrl :: Lens' Object (Maybe Text)
bnFileUrl = makeAesonLensMb "fileUrl" oRest

-- | The total number of unencoded, uncompressed octets contained
-- within the "data" field.
bnLength :: Lens' Object (Maybe Text)
bnLength = makeAesonLensMb "length" oRest

-- | An optional MD5 checksum calculated over the unencoded,
-- uncompressed octets contained within the "data" field
bnMd5 :: Lens' Object (Maybe Text)
bnMd5 = makeAesonLensMb "md5" oRest

-- | The MIME Media Type of the binary data contained within the object.
bnMimeType :: Lens' Object (Maybe Text)
bnMimeType = makeAesonLensMb "mimeType" oRest

-- event

-- | A collection object as defined in Section 3.5 of the JSON
-- Activity Streams specification that provides information about
-- entities that attended the event.
evAttendedBy :: Lens' Object (Maybe Collection)
evAttendedBy = makeAesonLensMb "attendedBy" oRest

-- | A collection object as defined in Section 3.5 of the JSON
-- Activity Streams specification that provides information about
-- entities that intend to attend the event.
evAttending :: Lens' Object (Maybe Collection)
evAttending = makeAesonLensMb "attending" oRest

-- | The date and time that the event ends represented as a String
-- conforming to the "date-time" production in [RFC3339].
evEndTime :: Lens' Object (Maybe UTCTime)
evEndTime = makeAesonLensMb "endTime" oRest

-- | A collection object as defined in Section 3.5 of the JSON
-- Activity Streams specification that provides information about
-- entities that have been invited to the event.
evInvited :: Lens' Object (Maybe Collection)
evInvited = makeAesonLensMb "invited" oRest

-- | A collection object as defined in Section 3.5 of the JSON
-- Activity Streams specification that provides information about
-- entities that possibly may attend the event.
evMaybeAttending :: Lens' Object (Maybe Collection)
evMaybeAttending = makeAesonLensMb "maybeAttending" oRest

-- | A collection object as defined in Section 3.5 of the JSON
-- Activity Streams specification that provides information about
-- entities that did not attend the event.
evNotAttendedBy :: Lens' Object (Maybe Collection)
evNotAttendedBy = makeAesonLensMb "notAttendedBy" oRest

-- | A collection object as defined in Section 3.5 of the JSON
-- Activity Streams specification that provides information about
-- entities that do not intend to attend the event.
evNotAttending :: Lens' Object (Maybe Collection)
evNotAttending = makeAesonLensMb "notAttending" oRest

-- | The date and time that the event begins represented as a String
-- confirming to the "date-time" production in RFC 3339.
evStartTime :: Lens' Object (Maybe UTCTime)
evStartTime = makeAesonLensMb "startTime" oRest

-- issue

-- | An array of one or more absolute IRI's that describe the type of
-- issue represented by the object. Note that the IRI's are intended
-- for use as identifiers and MAY or MAY NOT be dereferenceable.
isTypes :: Lens' Object (Maybe [Text])
isTypes = makeAesonLensMb "types" oRest

-- permission

-- | A single Activity Streams Object, of any objectType, that
-- identifies the scope of the permission. For example, if the
-- permission objects describes write permissions for a given file,
-- the scope property would be a file object describing that file.
pmScope :: Lens' Object (Maybe Object)
pmScope = makeAesonLensMb "scope" oRest

-- | An array of Strings that identify the specific actions associated
-- with the permission. The actions are application and scope
-- specific. No common, core set of actions is defined by this
-- specification.
pmActions :: Lens' Object (Maybe [Text])
pmActions = makeAesonLensMb "actions" oRest

-- place

-- | The latitude, longitude and altitude of the place as a point on
-- Earth. Represented as a JSON Object as described below.
plPosition :: Lens' Object (Maybe PlacePosition)
plPosition = makeAesonLensMb "position" oRest

-- | A physical address represented as a JSON object as described below.
plAddress :: Lens' Object (Maybe PlaceAddress)
plAddress = makeAesonLensMb "address" oRest

newtype PlacePosition = PPO { fromPPO :: Aeson.Object } deriving (Eq, Show)

instance FromJSON PlacePosition where
  parseJSON (Aeson.Object o) = do
    ensure "Position" o
      ["altitude", "latitude", "longitude"]
    return (PPO o)
  parseJSON _ = fail "\"Position\" not an object"

instance ToJSON PlacePosition where
  toJSON = Aeson.Object . fromPPO

newtype PlaceAddress = PAO { fromPAO :: Aeson.Object } deriving (Eq, Show)

instance FromJSON PlaceAddress where
  parseJSON (Aeson.Object o) = do
    ensure "Address" o
      [ "formatted"
      , "streetAddress"
      , "locality"
      , "postalCode"
      , "country"
      ]
    return (PAO o)
  parseJSON _ = fail "Address not an object"

instance ToJSON PlaceAddress where
  toJSON = Aeson.Object . fromPAO

-- role/group

-- | An optional Activity Streams Collection object listing the
-- members of a group, or listing the entities assigned to a
-- particular role.
rlMembers :: Lens' Object (Maybe [Object])
rlMembers = makeAesonLensMb "members" oRest

-- Task

-- | An Activity Streams Object that provides information about the
-- actor that is expected to complete the task.
tsActor :: Lens' Object (Maybe Object)
tsActor = makeAesonLensMb "actor" oRest

-- | A RFC 3339 date-time specifying the date and time by which the
-- task is to be completed.
tsBy :: Lens' Object (Maybe UTCTime)
tsBy = makeAesonLensMb "by" oRest

-- | An Activity Streams object describing the object of the task.
tsObject :: Lens' Object (Maybe Object)
tsObject = makeAesonLensMb "object" oRest

-- | An Array of other Task objects that are to be completed before
-- this task can be completed.
tsPrerequisites :: Lens' Object (Maybe [Object])
tsPrerequisites = makeAesonLensMb "prerequisites" oRest

-- | A boolean value indicating whether completion of this task is
-- considered to be mandatory.
tsRequired :: Lens' Object (Maybe Bool)
tsRequired = makeAesonLensMb "required" oRest

-- | An Array of other Task objects that are superseded by this task object.
tsSupersedes :: Lens' Object (Maybe [Object])
tsSupersedes = makeAesonLensMb "supersedes" oRest

-- | A string indicating the verb for this task as defined in Section
-- 3.2 of [activitystreams].
tsVerb :: Lens' Object (Maybe SchemaVerb)
tsVerb = makeAesonLensMb "verb" oRest

-- extra properties

-- | The additional @context@ property allows an 'Activity' to further
-- include information about why a particular action occurred by
-- providing details about the context within which a particular
-- Activity was performed. The value of the @context@ property is an
-- 'Object' of any @objectType@. The meaning of the @context@ property is
-- only defined when used within an 'Activity' object.
acContext :: Lens' Activity (Maybe Object)
acContext = makeAesonLensMb "context" acRest

-- | When appearing within an activity, the location data indicates
-- the location where the activity occurred. When appearing within an
-- object, the location data indicates the location of that object at
-- the time the activity occurred.
getLocation :: Lens' a Aeson.Object -> Lens' a (Maybe Object)
getLocation = makeAesonLensMb "location"

-- | Mood describes the mood of the user when the activity was
-- performed. This is usually collected via an extra field in the user
-- interface used to perform the activity. For the purpose of the
-- schema, a mood is a freeform, short mood keyword or phrase along
-- with an optional mood icon image.
oMood :: Lens' Object (Maybe Mood)
oMood = makeAesonLensMb "mood" oRest

-- | A rating given as a number between 1.0 and 5.0 inclusive with one
-- decimal place of precision. Represented in JSON as a property
-- called @rating@ whose value is a JSON number giving the rating.
oRating :: Lens' Object (Maybe Double)
oRating = makeAesonLensMb "rating" oRest

-- | The @result@ provides a description of the result of any particular
-- activity. The value of the @result@ property is an Object of any
-- objectType. The meaning of the @result@ property is only defined when
-- used within an 'Activity' object.
acResult :: Lens' Activity (Maybe Object)
acResult = makeAesonLensMb "result" acRest

-- | The @source@ property provides a reference to the original source of
-- an object or activity. The value of the @source@ property is an
-- Object of any objectType.
--
-- The @source@ property is closely related to
-- the @generator@ and @provider@ properties but serves the distinct
-- purpose of identifying where the activity or object was originally
-- published as opposed to identifying the applications that generated
-- or published it.
getSource :: Lens' a Aeson.Object -> Lens' a (Maybe Object)
getSource = makeAesonLensMb "source"

-- | When an long running Activity occurs over a distinct period of
-- time, or when an Object represents a long-running process or event,
-- the @startTime@ propertiy can be used to specify the
-- date and time at which the activity or object begins.
-- The values for each are represented as JSON Strings
-- conforming to the "date-time" production in RFC3339.
getStartTime :: Lens' a Aeson.Object -> Lens' a (Maybe Text)
getStartTime = makeAesonLensMb "startTime"

-- | When an long running Activity occurs over a distinct period of
-- time, or when an Object represents a long-running process or event,
-- the @endTime@ propertiy can be used to specify the
-- date and time at which the activity or object concludes.
-- The values for each are represented as JSON Strings
-- conforming to the "date-time" production in RFC3339.
getEndTime :: Lens' a Aeson.Object -> Lens' a (Maybe Text)
getEndTime = makeAesonLensMb "endTime"

-- | A listing of the objects that have been associated with a
-- particular object. Represented in JSON using a property named @tags@
-- whose value is an Array of objects.
oTags :: Lens' Object (Maybe [Object])
oTags = makeAesonLensMb "tags" oRest

-- mood

-- | Mood describes the mood of the user when the activity was
-- performed. This is usually collected via an extra field in the user
-- interface used to perform the activity. For the purpose of this
-- schema, a mood is a freeform, short mood keyword or phrase along
-- with an optional mood icon image.
newtype Mood = Mood { fromMood :: Aeson.Object } deriving (Eq, Show)

instance FromJSON Mood where
  parseJSON (Aeson.Object o) = do
    ensure "Mood" o ["displayname", "image"]
    return (Mood o)
  parseJSON _ = fail "Mood not an object"

instance ToJSON Mood where
  toJSON = Aeson.Object . fromMood

-- | Access to the underlying JSON object of a 'Mood'
moodRest :: Lens' Mood Aeson.Object
moodRest = makeLens fromMood (\ o' m -> m { fromMood = o' })

-- | The natural-language, human-readable and plain-text keyword or
-- phrase describing the mood. HTML markup MUST NOT be included.
moodDisplayName :: Lens' Mood Text
moodDisplayName = makeAesonLens "displayName" moodRest

-- | An optional image that provides a visual representation of the mood.
moodImage :: Lens' Mood MediaLink
moodImage = makeAesonLens "image" moodRest
