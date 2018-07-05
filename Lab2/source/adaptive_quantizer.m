function [ rec_signal, bits_per_frame ] = adaptive_quantizer( h_k, g_k, M, L, R, frame, T_g)
% Step 2.1 & 2.2 & 2.3 of the exercise using an adaptive quantizer
%
% Usage:
%         rec_signal = adaptive_quantizer( h_k, g_k, M, L, R, frame, T_g)
%
% Description:
%   Analysis of the input signal with h_k filters - downsample - 
%   quantize using an adaptive quantizer - upsample - synthesis
%   using g_k filters - sum all and create reconstrutive signal 
%   of given frame.
%
% In:
%   h_k : 32 analysis filters
%   g_k : 32 synthesis filters
%   M : Number of filters
%   L : Length of each filter
%   R : Levels of quantization of initial signal
%   frame : Input signal
%   T_g : Absolute Threshold of Hearing of signal
% Out:
%   rec_signal : Reconstructive signal
%   bits_per_frame : sum of bits used for this frame
%

%All the computations will be executed for every filter of the
%filterbank. Here we have all the necessary initializations.    
u_k = zeros(M,length(frame)+L-1); %Convolution of frame with each filter
y_k = zeros(M,ceil((length(frame)+L-1)/M)); %Downsampled convolution
quantized_y = zeros(M,ceil((length(frame)+L-1)/M));   %Quantized signal
rec_signal = zeros(639,1);   %final quantized signal per frame
bits_per_frame = 0;
for q = 1:M
    % Step 2.1 : Analysis with Filterbank
    u_k(q,:) = conv(h_k(q,:),frame);
    y_k(q,:) = downsample( u_k(q,:), M);
    
    % Step 2.2 : Quantization
    %Compute low indexes of each filter
    filter_idx = [(8*(q-1)+1):8*q];
    %Compute min value of T_g in the specific indexes
    min_Tg = min(T_g((filter_idx)));
    %Compute number of bits using the given type
    b_k = ceil( log2(R/min_Tg-1));
    bits_per_frame = bits_per_frame + b_k * length(y_k(q,:));
    levels = 2^b_k;
    max_y = max(y_k(q,:));
    min_y = min(y_k(q,:));
    range = max_y - min_y;
    D = range/levels;
    %Define partition and codebook for the quantization
    partition = min_y + [1:(levels-1)]*D;
    codebook = min_y + [0:(levels-1)]*D +D/2;
    [index,quantized_y(q,:)] = quantiz(y_k(q,:),partition,codebook);
    
    %Step 2.3 : Synthesis
    w_k = upsample(quantized_y(q,:) , M);
    x_final = conv( g_k(q,:), w_k);
    rec_signal = rec_signal + x_final';
end
