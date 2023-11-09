# Xenium Xplorer

Xenium Xplorer is an Android app designed for blockchain enthusiasts to explore and analyze blockchain data. This app offers real-time statistics and insights into the blockchain structure, providing valuable information for users interested in blockchain analytics.

## Features

- User-friendly interface developed with Flutter and Dart.
- Backend hosted on Amazon AWS EC2.
- Utilizes Python Flask and SQLite for managing and continuously collecting blockchain data.
- Supports real-time statistics on various blockchain parameters.
- Provides detailed insights into blockchain structure.

## Getting Started

Follow these steps to set up and run Xenium Xplorer locally:

1. Clone this repository.

`git clone https://github.com/nukee86/xnmxplorer.git`

2. Navigate to the project directory.

`cd xnmxplorer`

3. Create an `.env` file in the root directory (you can use the `.env.example` file as a template).

`cp .env.example .env`

4. Update the `.env` file with the required configuration, ensuring sensitive data like API URLs is kept private.

5. Install the necessary dependencies.

`flutter pub get`

6. Create flutter project in current dir.

`flutter create .`

7. Update `android/gradle/wrapper/gradle-wrapper.properties`:

`distributionUrl=https\://services.gradle.org/distributions/gradle-7.6.1-all.zip`

8. Run the app.

`flutter run`

## Contributing

Contributions to Xenium Xplorer are welcome! Here's how you can get involved:

1. Fork the repository.
2. Create your feature branch:

`git checkout -b feature/your-feature-name`

3. Commit your changes:

`git commit -m 'Add some feature'`

4. Push to the branch:

`git push origin feature/your-feature-name`

5. Create a pull request.

## Contact

If you have questions or need assistance, feel free to contact me at nukeecodes@gmail.com.

Happy exploring the blockchain with Xenium Xplorer!