Vonage Client SDK Video iOS release notes
=========================================

New features and changes
------------------------

### Version 2.29.0 -- December 2024

* This version of the SDK uses an updated version of WebRTC 121, which includes improvements in performance and stability.

* This version adds performance improvements for Single Peer Connection.

* This version of the SDK only supports iOS 15 or higher.

### Version 2.28.3 -- December 2024

* This version fixes an issue where, in some cases, toggling audio or video immediately after publishing would prevent video from being displayed.
 
* This version fixes an issue where, in some cases, applications running iOS 17.6.1 would crash.

### Version 2.28.2 -- September 2024

* This version fixes an issue where, in some cases, the audio level stayed the same when the publisher was muted.  

* This version fixes an issue where custom audio drivers could potentially cause a crash.  

* This version fixes an issue where, in some cases, audio from web client SDK users was garbled. 

### Version 2.28.1 -- August 2024

* This version adds a minimum required iOS version in the Info.plist. 

* This version fixes an issue where video was briefly stuttering after connecting to another user.

* This version fixes an issue where the video resolution was not updating when devices were rotated.  
  
### Version 2.28.0 -- June 2024

* This version adds support for [Single Peer Connection](https://tokbox.com/developer/guides/create-session/#single-peer-connection). When enabled, it reduces OS resource consumption, improves rate control, and in the case of mobile native devices, supports large sessions. See the documentation for the  `OTSessionSettings.singlePeerConnection` property.   

* This version adds support for advanced noise suppression. This uses the Vonage Media Library to provide enhanced noise cancellation. See the documentation for the `OTPublisherKit.audioTransformer` property. This was previously a beta feature. 

### Version 2.27.4 -- June 2024

* This version adds support for reading the Certificate Authority certificates in the trust store of the host so that it can use them as valid root certificates when connecting to OpenTok services.

* This version adds support for Apple's requirement of the
  [signature for the SDK](https://developer.apple.com/support/third-party-SDK-requirements).

* This version adds support for advanced noise suppression. This uses the Vonage Media Library to provide enhanced noise cancellation. See the documentation for the `OTPublisherKit.audioTransformer` property. This is a beta feature.
 
* This version reduces the size of the SDK by removing the Vonage Media Library code. In order to use methods that use the Vonage Media Library, you must load the Vonage Media Library separately from the Vonage Video iOS SDK. This includes using the `OTPublisherKit.audioTransformers` and `OTPublisherKit.videoTransformers` properties to apply audio and video transformers to the stream. For more information, see [Vonage Media Library integration](https://tokbox.com/developer/guides/vonage-media-processor/ios/#vonage-media-library-integration). 

* This version fixes a crash.  

### Version 2.27.3 -- April 2024

* This version adds a [privacy manifest required by Apple's App store](https://developer.apple.com/support/third-party-SDK-requirements).

### Version 2.26.3 -- April 2024

* This version adds a [privacy manifest required by Apple's App store](https://developer.apple.com/support/third-party-SDK-requirements).

### Version 2.25.5 -- April 2024

* This version adds a [privacy manifest required by Apple's App store](https://developer.apple.com/support/third-party-SDK-requirements).

### Version 2.27.2 -- March 2024

* This version fixes an issue where apps would sometimes crash when unpublishing.  

### Version 2.27.1 -- January 2024

* This version fixes a bug where `canSubscribe` returned incorrect information in `OTSessionCapabilities`.   

* This version fixes an issue where the state of captions was not properly updated for subscribers under certain circumstances. 

* This version fixes some crashes.   

* This version fixes an issue where some private classes were exposed. 

### Version 2.27.0 -- December 2023

* This version adds support for publisher audio fallback. This was previously a beta feature. See the [Publisher audio fallback](https://tokbox.com/developer/guides/audio-fallback/) documentation.  

* This version adds support for the VP9 codec in relayed sessions. For more information, see the [Video Codecs](https://tokbox.com/developer/guides/codecs/) documentation.  

* This version adds support for end-to-end encryption. You can enable end-to end-encryption using the `[OTSession setEncryptionSecret:secret:error:]` method. For more information, see the [End-to-End Encryption](https://tokbox.com/developer/guides/end-to-end-encryption) documentation.   

* This version adds support for adaptive media routing. For more information, see the [Adaptive Media Routing](https://tokbox.com/developer/guides/create-session/#adaptive-media-routing) documentation.  

* This version adds some memory management improvements.

* This version fixes an issue where certain events were being dropped.

### Version 2.26.2 -- November 2023

* This version adds support for publisher audio fallback. This is a beta feature. See the [Publisher audio fallback](https://tokbox.com/developer/guides/audio-fallback/) documentation.

* This version includes an updated version of WebRTC 99 with a fix for the CVE-2023-5217 vulnerability in the libvpx libraries.

### Version 2.26.1 -- September 2023

* This version fixes an issue where video dimensions were incorrect if users muted video.  

* This version fixes an issue where, in some cases, users were unable to connect to sessions with both custom TURN servers and IP Proxies enabled.  

* This version fixes an issue where, in some cases, using custom audio devices was causing publishing failures.  

* This version fixes some memory leaks.

* This version fixes an issue where it sometimes took longer than expected to disconnect from a session. 

* This version fixes an issue where, in some cases, setting the microphone to mute was causing a crash.  

### Version 2.26.0 -- August 2023

* This version adds support for the
  [Vonage Media Processor library](https://tokbox.com/developer/guides/audio-video/vonage-media-processor)
  and custom media transformers. You can apply custom video and audio transformations to video and audio
  streams using the `OTPublisherKit.videoTransformers` and `OTPublisherKit.audioTransformer` properties. This
  was previously a beta feature.

* This version adds support for more
  [Vonage Media Processor](https://tokbox.com/developer/guides/audio-video/vonage-media-processor) filters.
  The background blur filter now accepts a custom radius option. And there is a new background replacement
  filter. See the docs for the `OTPublisherKit.videoTransformers` property.

* This version adds support for [Live Captions](https://tokbox.com/developer/guides/live-captions/). See the docs for
  `OTPublisherKitSettings.publishCaptions` and `OTSubscriberKit.subscribeToCaptions`. This was previously a beta feature.

* This version fixes some compiler warnings.

* This version fixes an issue where the SDK was crashing for subscribers to streams published using the iOS SDK in relayed sessions.

### Version 2.25.3 -- July 2023

* This version fixes some inconsistent cleanup-related audio callbacks for custom devices.

### Version 2.25.2 -- May 2023

* This version adds support for Insertable Streams for video and audio. You can apply custom video and
  audio transformations to video and audio streams using the
 `OTPublisherKit.videoTransformers` and `OTPublisherKit.audioTransformer` properties. This is a beta feature.

* This version adds support for [Live Captions](https://tokbox.com/developer/guides/live-captions/). See the docs for
  `OTPublisherKitSettings.publishCaptions` and `OTSubscriberKit.subscribeToCaptions`. This is a beta feature.

* This version fixes an issue where captions were enabled by default.

### Version 2.25.1 -- May 2023

* Added support for Swift Package Manager: https://github.com/opentok/vonage-client-sdk-video.git.

* This version removes support for FAT binaries (previously available as 
  Pod "OpenTok").  Only XCFramework artifacts are supported (available as Pod "OTXCFramework").

* This version fixes linker errors when an application uses multiple WebRTC libraries.

* This version fixes some memory leaks.

* This version fixes an issue where occasionally the app would crash if it was publishing for a very 
  long time.  
  
### Version 2.25.0 -- April 2023

* This version of the SDK uses an updated version of WebRTC 99, which includes improvements in performance and stability.

* This version fixes an intermittent crash when running your application in debug mode. 

### Version 2.24.2 -- February 2023

* This version supports iOS 13 or higher.

* This version adds emulator support for M1-based CPUs.

* This version fixes an issue where the camera LED was not turned off when the video was muted. 

* This version fixes an issue where audio would remain muted for users under certain circumstances.

* This version fixes an issue where starting a session with muted video would disable scalable video.

* This version fixes an issue where publishing using Full High Definition (1080p) was causing scalable video to
  be disabled. 

### Version 2.24.1 -- December 2022

* This version fixes an issue where, in some cases, publishing may take longer than usual.

### Version 2.24.0 -- October 2022

* This version of the SDK uses WebRTC 99, which includes improvements in performance and stability.

* This version fixes an issue when AES-256 was enabled and applications could not connect to
  clients using on Safari 15.3 and below.

* This version fixes an issue in which applications could not connect to a session when IP Proxy
  was enabled.

* This version fixes an issue where there was an intermittent thread warning when initializing a publisher.  

### Version 2.23.1 -- August 2022

* This version fixes an issue that caused excessive bandwidth usage by streams in relayed sessions.

* This version fixes an issue where the app would occasionally crash due to audio issues. 

### Version 2.23.0 -- June 2022

* This version adds bandwidth consumption improvements in relayed sessions.

* Adding support for Full High Definition (1920x1080-pixel) resolution. You can specify 
  `OTCameraCaptureResolutionHigh1080p` as the `cameraResolution` property of 
  the `OTPublisherSettings` object you pass into the `[OTPublisher initWithDelegate:settings:]` method. 
  This was previously a private beta feature.

* This version implements [scalable video](https://tokbox.com/developer/guides/scalable-video/) support
  for screen sharing. See the `OTPublisherKitSettings.scalableScreenshare` property. This was previously a beta feature. 

* This version adds the ability to enable per-subscriber audio levels. See the docs for the 
  `OTSubscriberKit.audioVolume` property.  This was previously a beta feature.  

* This version fixes an issue where publishers of 1080p or 720p streams to
  [routed sessions](https://tokbox.com/developer/guides/create-session/#media-mode)
  published two [scalable video](https://tokbox.com/developer/guides/scalable-video/)
  layers instead of three.
  
* This version provides support for iOS 12 or higher.

### Version 2.22.3 -- May 2022

* This version fixes an issue where video would freeze if a Bluetooth headphone connection was disconnected
  during an ongoing video call. 

* This version fixes an intermittent issue where apps may crash when streams get dropped. 

* Adding support for Full High Definition (1920x1080-pixel) resolution. You can specify
  `OTCameraCaptureResolutionHigh1080p` as the `cameraResolution` property of
  the `OTPublisherSettings` object you pass into the `[OTPublisher initWithDelegate:settings:]` method.
  This is a private beta feature. Please contact Vonage like to enable this feature for your Video API project.

### Version 2.22.2 -- April 2022

* This version adds the ability to enable per-subscriber audio levels. See the docs for the 
  `OTSubscriberKit.audioVolume` property. This is a beta feature.

* This version implements [scalable video](https://tokbox.com/developer/guides/scalable-video/) support
  for screen sharing. See the `OTPublisherKitSettings.scalableScreenshare` property. This is a beta feature.  

* This version fixes a potential minor memory leak.

### Version 2.22.1 -- March 2022

* This version removes support for DTLS 1.0.

### Version 2.22.0 -- February 2022

* This version adds the ability to enable [Opus DTX](https://datatracker.ietf.org/doc/html/rfc7587#section-3.1.3).
  Use the `OTPublisherKitSettings.enableOpusDtx` property to enable Opus DTX. Enabling
  Opus DTX can reduce bandwidth usage in streams that have long periods of silence.
  This was previously a beta feature.

* This version removes support for cipher TLS_RSA_WITH_3DES_EDE_CBC_SHA.

* This version fixes a bug where video from [Broadcast extension-based]
  (https://github.com/opentok/opentok-ios-sdk-samples/tree/main/Broadcast-Ext) applications would stop
  publishing when in background mode.

### Version 2.21.3 -- January 2022

* This version fixes an issue where app audio gets lost after declining an incoming phone call.

### Version 2.21.2 -- November 2021

* This version fixes an issue where the audio bitrate set with the `OTPublisherKitSettings.audioBitrate`
  property was not used.

### Version 2.21.1 -- October 2021

* This version adds the ability to enable [Opus DTX](https://datatracker.ietf.org/doc/html/rfc7587#section-3.1.3).
  Use the `OTPublisherKitSettings.enableOpusDtx` property to enable Opus DTX. Enabling
  Opus DTX can reduce bandwidth usage in streams that have long periods of silence.
  This is a <i>beta</i> feature.

* This version fixes a bug where video from [Broadcast extension-based]
  (https://github.com/opentok/opentok-ios-sdk-samples/tree/main/Broadcast-Ext) applications may appear corrupt.

### Version 2.21.0 -- October 2021

* This version adds the ability for moderators to mute participants. This was previously a _beta_
  feature. See the docs for the `[OTSession forceMuteAll:error:]`, `[OTSession forceMuteStream:error:]`,
  and `[OTSession disableForceMute:error:]` methods. Note that the `[OTSession forceMuteAll:error:]` and
  `[OTSession forceMuteStream:error:]` methods no longer include an `options` parameter, like they did
  in the beta version.

* This version adds the ability to dynamically change how published video streams are optimized.
  This can improve video performance for some screen-sharing streams and in other conditions.
  This was previously a <i>beta</i> feature.  See the docs for the `[OTVideoCapture videoContentHint]` property.

* This version fixes an intermittent issue that caused applications to crash when a subscriber joins a session.

### Version 2.20.2 -- November 2021

* This version fixes an issue where the audio bitrate set with the `OTPublisherKitSettings.audioBitrate`
  property was not used.

### Version 2.20.1 -- August 2021

* This version adds the ability to dynamically change how published video streams are optimized.
  This can improve video performance for some screen-sharing streams and in other conditions.
  This is a <i>beta</i> feature. See the docs for the `[OTVideoCapture videoContentHint]` property.

* This version fixes an issue where an app may crash when gathering audio and video statistics for a subscriber.

### Version 2.20.0 -- May 2021

* This version adds the ability for moderators to mute participants. This is a <i>beta</i>
  feature. See the docs for the `[OTSession forceMuteAll:options:error:]` and
  `[OTSession forceMuteStream:options:error:]` methods.

* This version fixes the following issues:

  * The SDK may log extraneous warning messages when compiling.

  * The `Session.unpublish()` method may fail if called immediately after publishing.

### Version 2.19.1 -- April 2021

This version fixes the following issues:

* The publisher's audio does not resume after ending a phone call on iOS 14 while in an OpenTok session.

* A potential memory leak may occur when publishing stops.

### Version 2.19.0 -- February 2021

* This version of the SDK uses WebRTC 84, which includes improvements in performance and stability.

* This version adds support for RTC audio and video statistics for publishers and subscribers.
  See the docs for the `[OTPublisherKit getRtcStatsReport:]` and `[OTSubscriberKit getRtcStatsReport:]`
  methods.

* This version fixes an issue where the audio bitrate value set for publishers was handled incorrectly internally.

### Version 2.18.1 -- October 2020

This version fixes the following issues:

* The `[OTPublisherKitDelegate publisher:didFailWithError:]` message was not being sent
  in some scenarios where publishing failed.

* The SDK was not proxying all communications correctly when the IP Proxy feature was being used.

## Version 2.18.0 -- August 2020

* This version adds support for the [IP Proxy](https://tokbox.com/developer/guides/ip-proxy/) feature.

* This version fixes an issue in which an app could crash when using an
  `OTPublisherKitAudioLevelDelegate` instance, because the stream was not properly updated
  in the internal implementation.

## Version 2.17.1 -- July 2020

This version fixes the following issues:

* A Publisher property was not logged correctly causing information to be misrepresented in Inspector.

* The `OTSubscriberKit ` object was holding a strong reference to the `audioLevelDelegate` delegate.

## Version 2.17.0 -- April 2020

* This version adds `OTSessionBlockedCountry` as an additional error code for `OTSession` errors.

* This version deprecates the `OTSessionSettings.apiURL` property.

## Version 2.16.6 -- April 2020

This version fixes the following issue:

* The following WebRTC properties are now omitted for logging when the IP Proxy feature is used: `audioLocalAddress`, `audioRemoteAddress`, `videoLocalAddress`, and `videoRemoteAddress`.

## Version 2.16.5 -- March 2020

This version fixes the following issues:

* Some URLs in the code were preventing apps from receiving
  FirstNet certification. We have removed these URLs.

* This version fixes an issue when holding OpenTok audio and then answering
  a phone call using the CallKit API.

## Version 2.16.4 -- February 2020

This version fixes the following issues:

* The `OTSubscriber` object was holding a strong reference to its delegate.

* The video of the publisher could freeze when turning off headphones in an attempt to destroy 
  the connection between the iOS device and the bluetooth headset.

* The SDK was not proxying all HTTP requests when the IP Proxy feature was being used.

* The SDK was reporting incorrect values for the publisher's stream properties after the stream properties had changed.

## Version 2.16.3 -- September 2019

This version adds support for iOS 13 by fixing 
the issue where the application would crash using iOS 13 Metal renderer. 
It also fixes the following issues:

* After switching the publisher camera source from front to rear, the mirroring was incorrect.

* The `Stream.videoDimensions` property of a subscriber object was not updating when
 the orientation changed in the published stream.

* An app would crash when setting the frame size for a publisher or subscriber to zero.

## Version 2.16.2 -- August 2019

This version fixes the following issues:

* The `hasVideo` property of a subscriber's `stream` property
  is not updated when the stream's publisher starts or stops publishing video.

* The `hasAudio` property of a subscriber's `stream` property
  is not updated when when the stream's publisher starts or stops
  publishing audio.

* A publisher's view becomes stretched when the view is resized
  and its aspect ratio changes.

* Data for published streams is not showing up in
  [OpenTokInspector](https://tokbox.com/developer/tools/inspector/).

* Unsubscribing a subscriber when its stream is dropped results in
  an error.

* For a second OpenTok session an app connects to, publishers' streams
  do not contain audio.

Version 2.16.1 -- May 2019

* This version fixes an issue that was causing the SDK to log extraneous
  warning messages when compiling.

Version 2.16.0 -- April 2019

* This version adds a `OTSubscriberVideoEventCodecNotSupported` constant to
  the `OTSubscriberVideoEventReason` enum.

* This version adds a new `[OTVideoCaptureConsumer consumeImageBuffer:]`
  method. This is a beta feature. It lets you use a Core Video image buffer as
  the source for a custom video capturer.

* The default renderer for OTPublisher and OTSubscriber videos now use
  the Metal Renderer (and the Metal, MetalKit and MetalPerformanceShaders
  frameworks) on devices that have it available. Otherwise, it uses
  the OpenGL ES.

* This version of the SDK uses WebRTC 71, which includes improvements
  in performance and stability.

* This version fixes the following issues:

  * Apps would log this extraneous message to the console: "OpenTok console
    logger has not been set."

  * Apps could not publish when used with the Apple Broadcast extension.

Version 2.15.3 -- January 2019

* This version fixes an issue that caused apps to crash when
  receiving OpenTok signals [sent using the OpenTok REST
  API](https://tokbox.com/developer/guides/signaling/rest/).

Version 2.15.2 -- December 2018

* This version fixes the following issues:

  * Background audio from other apps did not pause and resume when
    an app connects and disconnects from an OpenTok session.

  * Apps could crash when accessing properties of the OTSubscriberKit's
    `stream` object in `[OTSubscriberKitDelegate subscriberVideoEnabled]`
    and `[OTSubscriberKitDelegate subscriberVideoDisabled]` messages
    (when the publisher of the stream toggles video on and off).

  * Crashes when using OpenTok with CallKit.

  * Reconnecting to sessions would occasionally fail.

Version 2.15.1 -- November 2018

* This version fixes the following issues:

  * Sending a signal to all clients would result in an error.

  * The `OTPublisher.viewScaleBehavior` property did not work in v2.15.0.

Version 2.15.0 -- October 2018

* This version adds a new OTPublisherKitNetworkStatsDelegate protocol,
  which provides audio and video statistics for a publisher. Set the
  `networkStatsDelegate` property of a OTPublisher instance to an object
  that implements the OTPublisherKitNetworkStatsDelegate protocol.

* Partners that have the allowed IP list [add-on feature](https://www.vonage.com/communications-apis/video/pricing/)
  enabled for an OpenTok project should set the new
  `[OTSessionSettings ipWhitelist]` proprty to `YES` when instantiating
  an OTSession object.

* This version of the SDK uses automatic reference counting.

Version 2.14.2 -- August 2018

* This version fixes a critical security vulnerability in the HTTP library. It is recommended that customers update to incorporate this fix.

Version 2.14.1 -- July 2018

* This version fixes the following issues:

  * Setting the `error` parameter of the `[OTVideoFrame setMetadata:error]`
    to `nil` could cause the application to crash.

  * Sessions sometimes fail to [automatically
    reconnect](https://tokbox.com/developer/guides/connect-session/ios/#automatic_reconnection)
    This issue was introduced in v2.14.0.

Version 2.14.0 -- April 2018

* This version adds an `[OTVideoFrame setMetadata:error:]` method, which you
  can use to set metadata for a video frame in a custom video capturer. When
  implementing a custom video renderer, you can use the new
  `OTVideoFrame.metadata` property to get the metadata.

* This version fixes a bug that caused the `videoPacketsLost` property of the
  OTSubscriberKitVideoNetworkStats object (sent to the
  `[OTSubscriberKitNetworkStatsDelegate subscriber:videoNetworkStatsUpdated:]`
  message) to always be set to 0.

Version 2.13.0 -- January 2018

* This version fixes the following issues:

  * Subscribing to high-resolution video would sometime result in cropping
    of the video.

  * Videos that use the scalable video feature would sometimes magnify.
    Scalable video is supported in sessions that use the [OpenTok media
    router](https://tokbox.com/developer/guides/create-session/#media-mode).

  * Clients disconnect from OpenTok sessions after switching the network
    interface multiple times.

  * Apps could crash when going into background mode.

  * A "Failed to make complete framebuffer object 8cd6" could result when
    rendering a video on a high-resolution screen (such as an iPhone 6+ screen
    or when streaming to to a large AirPlay screen).

  * One of the sample apps could result in a "Duplicated symbols linking
    OpenTok iOS SDK with the VideoDriver" error.

Version 2.12.1 -- October 2017

* This version fixes the following issues:

  * Failures when unsubscribing from an H.264 stream.

  * Destroying an `OTPublisher` may result in an `[AVCaptureSession stopRunning]` exception.

  * The `[OTPublisherKit publishVideo]` setting is not applied correctly when an app resumes
    from being in the background mode.

Version 2.12.0 -- September 2017

* iOS 11 support.

* This version adds a new `videoCapture` property to the OTPublisherSettings
  interface. It allows the application to start a new publisher with a screen
  capturer while there is another camera publisher already running.

* Interoperability with clients using [OpenTok.js in
  Safari](https://tokbox.com/developer/beta/safari/).

* This version fixes the following issues:

  * Publishing an audio-only stream after previously publishing video fails.

  * Applications crash if another user in a session disconnects while the local client's app
    is in the background.

  * Publishing and subscribing prevents apps from using Airplay.

Version 2.11.5 -- October 2017

* Fixed an issue in which the application crashes if the user disconnects while
  the application is in background.

Version 2.11.4 -- August 2017

* Fixed an issue in which publishers and subscribers go black or disappear
  when the Control Center is opened.
  
* Fixed an issue in which publishing never completes if you launch the app
  in the background using CallKit.
  
* Fixed broken video mirroring behavior in the publisher view when the app
  comes from background to foreground.

Version 2.11.3 -- July 2017

* This version fixes a crash when the publisher is created on app start up.

Version 2.11.2 -- June 2017

* When a publisher stops publishing (for example, when you call
  `[OTSession unpublish:error:]`), the `stream` property of the OTPublisherKit
  object is now set to `nil`. Previously, this property remained set to an
  OTStream object, which could cause apps to crash.

* Fixed intermittent crashes when you call `[OTSession unpublish:error:]`,
  `[OTSession disconnect:]`, then set the OTPublisher and OTSession objects
  to `nil`, and then try to reconnect and publish.

* Fixed intermittent issues that caused applications to crash in the
  background mode.

* This version fixes more IPv6 network connectivity issues that
  affected clients on T-Mobile.

Version 2.11.1 -- May 2017

* This version fixes some IPv6 network connectivity issues.
  This affected clients on T-Mobile.

* This version fixes an issue with re-subscribing to streams.

Version 2.11.0 -- April 2017

* Audio tuning API. Use the `OTPublisherKitSettings.audioBitrate` property
  to set the audio bitrate for a publisher. (For more information, see the
  reference documentation.)

* This version adds errors for stream and connection limits. These errors are
  useful in large OpenTok sessions:

  * If you call `[OTSession connectWithToken:error:]` when the session's
    connection limit has been exceeded, the
    `[SessionDelegate session:didFailWithError:]` message is sent with
    an OTError object that has it error code set to
    `OTSessionConnectionLimitExceeded`.

  * If you call `[Session subscribe:error:]` when the session's
    stream limit has been exceeded, the
    `[OTSubscriberKitDelegate subscriber:didFailWithError:]` message is
    sent with an OTError object that has it error code set to
    `OTSubscriberStreamLimitExceeded`.

  See the [beta programs](https://tokbox.com/developer/beta/) page for
  information on supporting sessions with up to 3,000 real-time viewers.

* This version re-enables H.264 video codec support in
  [relayed](http://tokbox.com/opentok/tutorials/create-session/#media-mode)
  sessions between iOS devices.

* This version of the SDK uses WebRTC 56, which includes improvements in performance and stability.

* This version fixes the following issues:

  * The CocoaPod platform version for this release of the OpenTok iOS SDK is set to 8.0.
    This means that CocoaPods will fetch this version of the SDK for projects that have the
    deployment target set to 8.0 or greater.

  * This version re-enables h.264 support in relayed sessions between two iOS devices.
    This can reduce CPU and battery usage.

  * Fixed issues with [automatic
    reconnection](https://tokbox.com/developer/guides/connect-session/ios/#automatic_reconnection)
    which could result in applications crashing.

Version 2.10.2

* This version fixes IPv6 network connectivity issues on iOS 10.2.
  This affected clients on T-Mobile.

Version 2.10.1

* This version fixes a bug that prevented you from setting the OTSubscriberKitDelegate to nil.

* This version corrects some Swift type annotations.

Version 2.10.0

* This version adds new methods for initializing OTSession, OTPublisher, and
  OTPublisherKit objects:

  * `[OTSession initWithApiKey:sessionId:delegate:settings:]`
  * `[OTPublisher initWithDelegate:settings:]`
  * `[OTPublisherKit initWithDelegate:settings:]`

  The new `OTSessionSettings`, `OTPublisherSettings`, and
  `OTPublisherKitSettings` classes let you define any combination of
  initialization settings to be used with the new initialization methods.

  The existing methods for initializing these objects are deprecated.

* This version adds annotations in Objective-C to improve Swift development.

* Fixed an issue that was limiting the number of subscribers. On the iPhone 7,
  tests have shown support for subscribing to as many as 20 simultaneous
  low-resolution (200x200-pixel, 15 frames per second) streams.

* Fixed a crash when a connection is dropped.

* Fixed linker warnings for incorrect visibility settings.

* This version includes an internal logging change that improves performance.

* The size of the framework is reduced (from 174M to 137M).

Version 2.9.2

* This version fixes an issue with automatic reconnection when switching between networks.
  For more information on automatic reconnection, see
  https://tokbox.com/developer/guides/connect-session/ios/#automatic_reconnection.

Version 2.9.1

* iOS 10.0.2 introduced a change in the behavior of system
  DNS resolution, which caused an issue with IPv6 resolution
  in the OpenTok SDK. This issue prevented apps from being
  accepted into the app store. This version fixes the issue.

Version 2.9.0

* This version adds support for bitcode. (Previously, this was only available
  in a beta build of the OpenTok iOS SDK.)

  Note that while bitcode support increases the size of the .ipa file,
  the download size is smaller after the app is compiled and optimized
  in the App Store. Also, the app download size becomes significantly
  smaller due to app slicing. When installing your app, the device
  downloads only the architecture it requires: armv7, armv7s, or arm64
  (instead of downloading all of the architectures included in the SDK).
  For more information on bitcode and app slicing, see
  https://developer.apple.com/library/tvos/documentation/IDEs/Conceptual/AppDistributionGuide/AppThinning/AppThinning.html.

  You can use the OpenTok iOS SDK in apps that have bitcode enabled as well as
  in those that do not.

* The OpenTok Media Router now includes the OpenTok scalable video feature
  (previously in beta). For more information, see the [OpenTok Media
  Router](https://tokbox.com/developer/guides/create-session/#media-mode)
  documentation.

* This version adds an `OTSession.capabilities` property. Use this property
  to check whether the client can publish streams to an OpenTok session,
  based on the role assigned to the token used to connect to the session.

* This version fixes issues when publishing streams on devices that use
  the A5 processor (including the iPhone 4S, the iPod Touch 5th generation,
  the iPad 2, and the iPad Mini 1st generation).

* Please upgrade your apps to use the latest versions of the [OpenTok server
  SDKs](https://tokbox.com/developer/sdks/server/). These now use JSON web
  tokens (JWT) for authentication. JWT provides increased security along with
  standards-based encoding, decoding, and verification. The old form of
  authentication will expire in July 2017. Also, if you use the OpenTok REST API
  (instead of the server SDKs), please use JWT to authenticate calls to the
  OpenTok REST methods (see
  [this topic](https://tokbox.com/developer/rest/#authentication) on
  authentication).

Version 2.8.4

* iOS 10.0.2 introduced a change in the behavior of system
  DNS resolution, which caused an issue with IPv6 resolution
  in the OpenTok SDK. This issue prevented apps from being
  accepted into the app store. This version fixes the issue.

Version 2.8.3

* This version fixes an issue in which apps connecting iOS clients only using
[relayed](http://tokbox.com/opentok/tutorials/create-session/#media-mode)
sessions would crash when being restored from the background.

Version 2.8.2

* This version adds support for IPv6. You will need to upgrade to this version to get your app
  approved in the App Store (which now requires IPv6 support in apps). For more information, see
  [this Vonage Support
  FAQ](https://support.tokbox.com/hc/en-us/articles/360029732871-iOS-IPv6-Support-Frequently-Asked-Questions).

* Fixed an issue that caused clients to occasionally disconnect from sessions on
  poor or low-bandwidth networks.

Version 2.8.1

* This version fixes an audio-video synchronization issue in version 2.8.0.

* Note that we have added TLS support added to OpenTok TURN servers. This fixes
  media streaming for clients behind network firewalls that block non-TLS
  traffic over port 443.

Version 2.8.0

* This version fixes H.264 video codec support. This was disabled in
  a previous version. The new version adds improved performance. The H.264
  video codec is available for streaming between iOS devices only and
  in relayed sessions.

* This version fixes multiple audio issues.

* This version of the SDK uses WebRTC 49.

Version 2.7.1

* We have fixed the following issues:

  * If an app using OpenTok is running in the background when
    a phone call is received and the call duration is more than 10 seconds,
    the app sometimes crashes when the call finishes.

  * Distorted "robotic" audio when switching from the loudspeaker
    to a Bluetooth headset.

  * Calling
    `[OTPublisher initWithDelegate:name:cameraResolution:
    cameraFrameRate:]` can take long (10 secs) to complete.

  * Apps using OpenTok sometimes crash when the user switches
    the network connection (for example, from Wi-Fi to cellular).

Version 2.7.0

* Setting the frame rate and resolution for a published stream using the default
  camera video capturer. A new
  `OTPublisher initWithDelegate:name:cameraResolution:cameraFrameRate:]` method
  includes parameters for setting the frame rate and resolution of the stream.

* New methods for getting audio and video statistics for a stream. You can now
  set a delegate object to monitor the following statistics for a subscriber's
  stream:

  * Total audio and video packets lost
  * Total audio and video packets received
  * Total audio and video bytes received

  See the documentation for the `OTSubscriberKit.networkStatsDelegate` property.

* Fixed an issue preventing connections from working while the device is locked
  and app Data Protection enabled.

* Fixed an issue that was causing apps to crash when disconnecting from an
  OpenTok session.

Version 2.6.1

* Fixed iOS 9 crash in the video renderer.

* Fixed audio distortion issue on the iPhone 6s and 6s+ running in iOS 9.

* Fixed the publisher video in the XCode iOS 9 Simulator.

Version 2.6.0

* Added `OTPublisher.viewScaleBehavior` and `OTSubscriber.viewScaleBehavior`
  properties to allow easily switching between common scaling methods without
  using a custom video renderer.

* Added the `[OTSession reportIssue:]` method. You can call this method
  when your app experiences an issue. The method sets an issue ID,
  which you can use with the
  <a href="https://tokbox.com/developer/tools/Inspector">Inspector</a>
  or when discussing an issue with the Vonage Video API support team.

* Increased the default video resolution and frame rate for OTPublisher.

* Improved audio device handling.

* H264-related bug fixes and improvements (in relayed one-to-one sessions
  between iOS devices).

* Fixed the the following issues:

  * Data was sent over WWAN when WiFi was available.

  * Audio was going to the receiver (instead of the speaker) after a phone call
    ended on the device.

  * The initial `videoDimensions` property of an OTStream was incorrect.

  * When unpublishing a stream, audio for subscribers was dropped.

Version 2.5.0

* Added hardware-accelerated H.264 support for relayed one-to-one sessions
  between iOS devices.

* Added proxy support.

* Added the implementation of the
 `[OTPublisher initWithDelegate: name: audioTrack: videoTrack:]`
  method (inherited from OTPublisherKit).

* Removed clang autolink feature from compilation.

* Fixed broken video mirroring behavior in the publisher view.

* Note that the samples directory is no longer included in the SDK bundle.
  The sample code is now available at the open-source [opentok-ios-sdk-samples
  repo](https://github.com/opentok/opentok-ios-sdk-samples)
  on GitHub. This allows us to keep it up to date and provide developers with
  latest version of the sample code. Feel free to clone the repo or download
  the source code to see the best-practice examples of OpenTok usage.

* All calls to AudioUnitGetProperty were removed from the remote I/O thread (in
  both the SDK and in the external audio device sample app).

Version 2.4.1

* Previous versions of the SDK would use the mobile data connection to transmit
and receive media streams when a Wi-Fi network was available. We have fixed this
issue.

* This version adds support for interactivity with clients using Firefox 38
in relayed OpenTok sessions (sessions that do not use [the OpenTok Media
Router](http://tokbox.com/opentok/tutorials/create-session/#media-mode )).

* Version 2.4.1 and 2.4.0 require different libraries that were required by
previous versions of the OpenTok iOS SDK. When moving a project from using
version 2.3.1, you need to include the VideoToolbox.framework, and you need to
remove libstdc++. For complete details, see "Using the SDK" in the README.md
file of the SDK.

* Fixed an issue in which an app could deadlock when starting or stopping audio
  or receiving an incoming call.

* The OpenTok iOS SDK is now available as the Pod "OpenTok", for use with
  [CocoaPods](http://cocoapods.org/).

Version 2.4.0

* This version adds support for the arm64 architecture.

* This version adds support for screen sharing. When publishing a screen-sharing
  stream, set the `videoType` property of the OTPublisherKit object and
  pass in `OTPublisherKitVideoTypeScreen` (defined in the
  OTPublisherKitVideoType enum). This optimizes the video encoding for screen
  sharing. It is recommended to use a low frame rate (5 frames per second or
  lower) with screen sharing. When using the screen video type in
  a session that uses the OpenTok Media Server, you should set the
  `[OTPublisherKit audioFallbackEnabled]` property to `NO` to disable
  the audio-only fallback feature, so that the video does not drop out
  in subscribers. See [the OpenTok Media
  Router](http://tokbox.com/opentok/tutorials/create-session/#media-mode ).

  When a stream is created in a session, you can determine the video type
  of the stream (screen or camera) by checking the `videoType` property of
  the OTStream object. The type of stream is defined by constants in the
  OTStreamVideoType enum: `OTStreamVideoTypeScreen` and
  `OTStreamVideoTypeCamera`.

  To publish a screen-sharing stream, you need to implement a custom video
  capturer for the OTPublisherKit object. For sample code that publishes a
  screen-sharing stream, see the "Screen-Sharing" app in the samples directory.

* You can disable the audio-only fallback feature for a published stream by
  setting the `audioFallbackEnabled` property of the OTPublisher object to
  `NO`. The audio-fallback feature is available in sessions that use the
  [OpenTok Media
  Router](http://tokbox.com/opentok/tutorials/create-session/#media-mode). With
  the audio-fallback feature enabled (the default), when the OpenTok
  Media Router determines that a stream's quality has degraded significantly for
  a specific subscriber, it disables the video in that subscriber in order to
  preserve audio quality. For streams that use a have the video type set to
  `OTStreamVideoTypeCamera`, the audio-fallback feature is enabled by default.
  For streams that have the video type set to `OTStreamVideoTypeScreen`, the
  audio-fallback feature is disabled by default.

Version 2.3.1

* This version fixes a bug that cause apps to crash when running in iOS 6.

Version 2.3.0

* This version adds support for armv7s and i386 architectures (in addition to
  armv7). You can now target the iOS Simulator. However, the Xcode iOS Simulator
  does not provide access to the camera. When testing in the iOS Simulator, an
  OTPublisher object uses a demo video instead of the camera.

* This version includes a new custom audio driver API. This lets you use
  custom audio streams and define the audio device used to capture and render
  audio data. The following new classes and protocols support the custom audio
  driver API:

  * OTAudioDeviceManager -- Use this class to set the app to specify a custom
  audio device for use in the app.

  * OTAudioDevice -- Defines an audio device for use in a session.

  * OTAudioBus -- The audio bus marshals audio data between the network and
  the audio device.

  * OTAudioFormat -- Defines the format of the audio.

* There are new delegate protocols and messages for getting the audio level of a
  publisher or subscriber. See the `OTPublisherKit.audioLevelDelegate` property
  and the `OTPublisherKitAudioLevelDelegate` protocol, as well as the
  `OTSubscriberKit.audioLevelDelegate` property and the
  `OTSubscriberKitAudioLevelDelegate` protocol.

* The new `[OTSubscriberKitDelegate subscriberVideoEnabled:reason:]` message is sent when
  a subscriber's video stream starts (when there previously was no video) or resumes
  (after video was disabled).

* The `reason` parameter has been added to the
  `[OTSubscriberKitDelegate subscriberVideoDisabled:reason:]` message. This parameter
  describes the reason why the subscriber video is being disabled.
  In the previous version, this message was only sent when the video was
  disabled due to changes in the stream quality (in a session that uses the
  OpenTok Media Router). In version 2.3.0, the message is also sent if the
  publisher stops sending a video stream or the subscriber stops subscribing to
  it (and the `reason` parameter value will be set accordingly).

* The new `[OTSubscriberKitDelegate subscriberVideoDisabledWarning:]` message is
  sent when the OpenTok Media Router determines that the stream quality has
  degraded and the video will be disabled if the quality degrades more. The new
  `[OTSubscriberKitDelegate subscriberVideoDisabledWarningLifted:]` message
  is sent when the stream quality improves. This feature is only available in
  sessions that use the OpenTok Media Router (sessions with the
  [media mode](http://tokbox.com/opentok/tutorials/create-session/#media-mode)
  set to routed), not in sessions with the media mode set to relayed.

* This version adds support for iOS 8.

Version 2.2.1

* Updated to use version 1.0.1h of OpenSSL.
* Created backwards compatibility with OpenTok iOS SDK 2.1.7 (subscriber
orientation).

Version 2.2.0

* For a list of new features and changes, see
[Migrating to version 2.2 of the OpenTok SDK]
(http://tokbox.com/opentok/libraries/client/ios/migrating-to-version-2.2.html).

Known issues
------------

### Important changes to iOS 14 networking affecting relayed sessions

With iOS 14, Apple introduces local network privacy (see
[this video](https://developer.apple.com/videos/play/wwdc2020/10110)).

Beginning in iOS 14, the operating system will prompt the user for permission
when an application attempts to subscribe to clients on the same local network
in a [relayed session](https://tokbox.com/developer/guides/create-session/#media-mode).
The default text in the notification says that the app "would like to find and connect
to devices on your local network."

In a relayed session, the Vonage Video API uses the local network to discover
and connect to video participants on your local network when possible. If clients
cannot connect on the local network, an application will use the OpenTok
TURN server to relay audio-video streams.

If the user does not accept the permission, the attempt to subscribe can fail
if the client cannot connect to the OpenTok TURN server. In this case,
after the permission is rejected, any future attempts to subscribe to clients on
the same network will also fail unless the user changes the permission in Settings.
Unfortunately, iOS does not provide an API for an application to determine if
the user has accepted or rejected this permission.

It is important to note that this does not apply to video sessions that use the
[OpenTok Media Router](https://tokbox.com/developer/guides/create-session/#media-mode),
as media is sent over the internet rather than the local network.

If your application uses a relayed session, we encourage you to to add a descriptive
custom usage string to inform the user why the application needs this permission:

1. In Xcode, open your app's info.plist file.

2. In the info.plist editor, right-click the left-hand column and select **Add Row**
   (or click **+**) to add a setting for *Privacy - Local Network Usage Description*.

3. Edit the value for this string to describe how your app uses this permission.

   For example, add "This app uses the local network to discover and connect to
   video participants on the same network when possible."

The prompt to the user will include this description.

For applications which cannot use routed sessions and do not wish the user
to be prompted for local network access, you can use the following code, which forces
the application to use TURN servers:

##### Objective-C

```
OTSessionSettings *settings = [[OTSessionSettings alloc] init];
OTSessionICEConfig *myICEServerConfiguration = [[OTSessionICEConfig alloc] init];
myICEServerConfiguration.transportPolicy = OTSessionICETransportRelay;
settings.iceConfig = myICEServerConfiguration;
session = [[OTSession alloc] initWithApiKey:kApiKey
                                   sessionId:kSessionId
                                    delegate:self settings:settings];
```

##### Swift

```
let settings = OTSessionSettings()
let myICEServerConfiguration = OTSessionICEConfig()
myICEServerConfiguration.transportPolicy = .relay
settings.iceConfig = myICEServerConfiguration
let session = OTSession(apiKey: apiKey, sessionId: sessionId, delegate: self, 
                        settings: settings)
```

### Other known issues

In OpenTok sessions that use H.264 video, CPU usage can increase to
a significant level if the app uses a publisher and four or more subscribers
simultaneously.

This version of the OpenTok iOS SDK does not support displaying videos using
Apple AirPlay.

In a session with the [media
mode](http://tokbox.com/opentok/tutorials/create-session/#media-mode)
set to relayed, only one client can subscribe to a stream published by an
iOS device.

The Xcode iOS Simulator does not provide access to the camera. When testing in
the iOS Simulator, an OTPublisher object uses a demo video instead of the
camera.

Subscribing to screen-sharing streams (see "New features and changes - Version
2.4") is not supported in the OpenTok iOS SDK version 2.3 and older. You must
upgrade to version 2.4.

If you are using a version of Xcode prior to 7.2.0, do not use the `-all_load`
linker flag. Instead, use the `-force_load` linker flag to load specific
libraries that require it.

The OpenTok iOS SDK links to the libc++ standard library. If another library
that links to the libc++ standard library was compiled in a version of Xcode
older than 6.0.0, it may result in segfaults at run time when using it with the
OpenTok iOS SDK. Known incompatible libraries include, but are not limited to,
Firebase (versions earlier than 2.1.2 -- see
https://code.google.com/p/webrtc/issues/detail?id=3992) and Google Maps
(versions earlier than 1.9.0). To fix this issue, download a version of the
other library that was compiled using Xcode 6.0.0 or later.

Video streaming is prevented on networks that have firewalls that use
authenticated proxies. This is due to a core issue with the current underlying
WebRTC implementation. (See [this Chromium bug
report](https://code.google.com/p/chromium/issues/detail?id=439560).)

In relayed sessions, applications do not display the red bar when running
in the background, if no client subscribes to your stream before the app goes
into background mode.

When setting a proxy URL (using the `Session.Builder.setProxyUrl()` method), please use the 
absolute URL root path only. Using the proxy path in the URL does not work currently 
and is a known bug. Hence "https://my-proxy.herokuapp.com" and 
"https://my-proxy.herokuapp.com:443" are acceptable, while 
"https://my-proxy.herokuapp.com/" and "https://my-proxy.herokuapp.com/my-beta-app/version5" are not.
