# JamWithMusicApp
Jam With Music App Prive GitHub for future employers'

Initial Vision for JamWith

My vision for JamWith was to create an app that allowed for these four main tasks: 

1.	Record a solo/play along with a predefined base track 
2.	 Record an original, multi-tracked audio piece
3.	Record a video of the user engaging in these acts
4.	Sharing the final product with other users through JamWith or other social media platforms

These tasks originally call for a multitude of different steps and a complex setup.  My goal was to allow for far less effort on the user side while maintaining a degree of quality in the content created.

Some Common iOS practices that I used through this app include:

•	MVC – As the apps main code base began to grow in size, it was vital for me to conform to a strict structure that would allow for the easiest degree of maintainability.  It was a top priority of mine to divide each part of the app up to allow for separation of concerns.

•	Delegation and Protocols – This app relied heavily on delegation and protocols to produce its final product.  The app essentially goes through different stages as the user progresses and it was vital to communicate data and events between different objects while maintaining a limited scope.

•	File Management- This app allows the user to create content.  There was a strong need to implement some sort of file system architecture to aid in the management of different sets of files and their associated attributes.   The app also allows the user to change certain aspects of objects during the process of creating (UI look and feel, audio length, audio times, effects, ect.) and a degree of management was vital to complete these tasks.

•	Knowledge of particular iOS Frameworks- Relied HEAVILY on AV Foundation including the new AVAudioEngine and all of its related classes, AVComposition, AVCaptureSession and its components, and various other AV classes.

•	UI Design / User standpoint perspective – When envisioning how users would communicate with this app, I wanted to create an experience that was rich and fulfilling while maintaining an element of simplicity.  I believe this is a vital part to any UI design and continually asked myself throughout this process if I was maintaining this vision.  This included me having to abandon some of my own ideas to manage this vision (which I believe is a skill in itself).

•	Auto Layout / Constraints / Handling an Ever Changing Environment -  With a wide array of screen sizes and the demand for a dynamic environment, it was vital that the elements on the screen conform to a design that allowed them to adopt to these differences.

•	Use of Grand Central Dispatch- With complex and memory heavy operations can come a decrease in “flow” within the application.  The use of GCD was important when maintaining this flow through the application.  While complex operations were tasked to be completed in the background, the users interface was left unscathed with, at worst, a mere activity indicator.

Other iOS practices I used

•	View / Layer Design

•	Sub Classing

•	Categories

•	Knowledge of General iOS Frameworks

•	Knowledge of Hardware 

•	Re-Usable Coding

•	Notifications / KVO

•	X-code / Interface Builder

Teamwork and Communication aspects

While working on this project I had the opportunity to work with another developer.  Together we were able to solve problems and create an elegant design that allowed me to meet my vision for this app.  In order for this to happen we had to communicate (in person and long distance) our ideas and work as a team to come to agreement on many different UI and internal decisions. 


