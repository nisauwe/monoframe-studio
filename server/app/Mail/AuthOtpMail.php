<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class AuthOtpMail extends Mailable
{
  use Queueable, SerializesModels;

  public string $code;
  public string $title;
  public string $messageText;
  public int $minutes;

  public function __construct(
    string $code,
    string $title,
    string $messageText,
    int $minutes = 10
  ) {
    $this->code = $code;
    $this->title = $title;
    $this->messageText = $messageText;
    $this->minutes = $minutes;
  }

  public function build()
  {
    return $this
      ->subject($this->title)
      ->view('emails.auth-otp')
      ->with([
        'code' => $this->code,
        'title' => $this->title,
        'messageText' => $this->messageText,
        'minutes' => $this->minutes,
      ]);
  }
}
